import SwiftUI
import WebKit
import Combine
import AppKit
import MediaPlayer
import WidgetKit
import os

private let ytmLogger = Logger(subsystem: "com.valentin.YmacPlayer", category: "Controls")

// MARK: - Weak Script Message Handler Proxy

private final class WeakScriptMessageHandler: NSObject, WKScriptMessageHandler {
    private weak var delegate: WKScriptMessageHandler?

    init(delegate: WKScriptMessageHandler) {
        self.delegate = delegate
        super.init()
    }

    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        delegate?.userContentController(userContentController, didReceive: message)
    }
}

// MARK: - Main Player Controller

@MainActor
final class YTMController: NSObject, ObservableObject, WKScriptMessageHandler, WKNavigationDelegate {

    static let shared = YTMController()

    let webView: WKWebView
    private var backgroundWindow: NSWindow?
    private(set) var userWantsPlayback: Bool = false
    private var shouldAutoPlayOnLoad: Bool = false
    nonisolated(unsafe) private var sleepWakeTask: Task<Void, Never>?
    nonisolated(unsafe) private var artworkDownloadTask: Task<Void, Never>?
    nonisolated(unsafe) private var sleepObserverTasks: [Task<Void, Never>] = []
    nonisolated(unsafe) private var widgetReloadTask: Task<Void, Never>?
    private var inFlightArtworkUrl: String = ""
    private var pendingPlaylistLoadId: String = ""
    private var pendingPlaylistLoadDate: Date = .distantPast
    private var lastLikeActionDate: Date = .distantPast
    private var lastRepeatActionDate: Date = .distantPast
    private var lastShuffleActionDate: Date = .distantPast
    private var userExplicitlyResetPlaylist: Bool = false

    @Published var isPlaying: Bool = false
    @Published var currentTitle: String = "Ymac Player"
    @Published var currentArtist: String = ""
    @Published var artworkUrl: String = ""

    @Published var userPlaylists: [YTMPlaylist] = []
    @Published var queue: [YTMQueueItem] = []

    @Published var isLiked: Bool = false
    @Published var isDisliked: Bool = false
    @Published var isShuffle: Bool = false
    @Published var repeatMode: Int = 0

    @Published var currentTime: Double = 0
    @Published var duration: Double = 0
    @Published var isEditingSlider: Bool = false

    @Published var currentPlaylistId: String = ""
    @Published var hasSelectedPlaylist: Bool = false
    @Published var isLoggedIn: Bool = true
    @Published var currentLanguage: AppLanguage = .english
    @Published var libraryFilter: LibraryFilter = .favoritePlaylists

    var hasActiveTrack: Bool {
        return !currentTitle.isEmpty &&
               currentTitle != "Ymac Player" &&
               currentTitle != "Ymac" &&
               currentTitle != "YouTube Music"
    }

    private var lastLoadedArtworkUrl: String = ""
    private var cachedArtworkImage: NSImage?
    private let sharedDefaults = UserDefaults(suiteName: "9R2Z2PT297.group.com.ymacplayer")

    private var lastWidgetTitle: String = ""
    private var lastWidgetArtist: String = ""
    private var lastWidgetIsPlaying: Bool = false
    private var lastWidgetIsShuffle: Bool = false
    private var lastWidgetRepeatMode: Int = 0
    private var lastWidgetIsLoggedIn: Bool = true
    private var lastWidgetHasSelectedPlaylist: Bool = false
    private var lastWidgetDuration: Double = 0
    private var lastWidgetPlaylists: [YTMPlaylist] = []

    override init() {
        if let savedLanguage = UserDefaults.standard.string(forKey: "appLanguage"),
           let language = AppLanguage(rawValue: savedLanguage) {
            currentLanguage = language
        }

        if let savedFilter = UserDefaults.standard.string(forKey: "libraryFilter"),
           let filter = LibraryFilter(rawValue: savedFilter) {
            libraryFilter = filter
        }

        let configuration = WKWebViewConfiguration()
        configuration.mediaTypesRequiringUserActionForPlayback = []

        let contentController = WKUserContentController()
        configuration.userContentController = contentController

        webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 1280, height: 800), configuration: configuration)
        webView.customUserAgent = """
        Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) \
        WebKit/605.1.15 (KHTML, like Gecko) \
        Version/17.6 Safari/605.1.15
        """

        super.init()

        webView.navigationDelegate = self
        contentController.add(WeakScriptMessageHandler(delegate: self), name: "ytmBridge")
        setupRemoteCommands()
        setupDarwinNotificationListeners()
        setupSleepNotificationObserver()
        injectJavaScript()
        attachToBackgroundWindow()

        let initialURLString = libraryFilter == .playlists
            ? "https://music.youtube.com/library/playlists"
            : "https://music.youtube.com"
        if let url = URL(string: initialURLString) {
            webView.load(URLRequest(url: url))
        }
    }

    deinit {
        sleepWakeTask?.cancel()
        artworkDownloadTask?.cancel()
        widgetReloadTask?.cancel()
        sleepObserverTasks.forEach { $0.cancel() }
        CFNotificationCenterRemoveEveryObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            Unmanaged.passUnretained(self).toOpaque()
        )
    }

    // MARK: - Sleep & Power Management

    private func setupSleepNotificationObserver() {
        sleepObserverTasks.forEach { $0.cancel() }
        sleepObserverTasks.removeAll()

        let center = NSWorkspace.shared.notificationCenter

        let sleepTask = Task { @MainActor [weak self] in
            for await _ in center.notifications(named: NSWorkspace.willSleepNotification) {
                self?.handleSleep()
            }
        }
        sleepObserverTasks.append(sleepTask)

        let screenSleepTask = Task { @MainActor [weak self] in
            for await _ in center.notifications(named: NSWorkspace.screensDidSleepNotification) {
                self?.handleSleep()
            }
        }
        sleepObserverTasks.append(screenSleepTask)

        let wakeTask = Task { @MainActor [weak self] in
            for await _ in center.notifications(named: NSWorkspace.didWakeNotification) {
                self?.handleWake()
            }
        }
        sleepObserverTasks.append(wakeTask)

        let screenWakeTask = Task { @MainActor [weak self] in
            for await _ in center.notifications(named: NSWorkspace.screensDidWakeNotification) {
                self?.handleWake()
            }
        }
        sleepObserverTasks.append(screenWakeTask)
    }

    private func handleSleep() {
        sleepWakeTask?.cancel()
        userWantsPlayback = false
        shouldAutoPlayOnLoad = false
        isPlaying = false
        runJS("""
        window.isSystemSleeping = true;
        if (typeof window.setUserWantsPlayback === 'function') {
            window.setUserWantsPlayback(false);
        } else {
            window.userWantsPlayback = false;
            try { sessionStorage.setItem('__ymacUserWantsPlayback', 'false'); } catch (e) {}
        }
        var v = document.querySelector('video');
        if (v) {
            v.pause();
            v.muted = true;
        }
        """)
        updateNowPlayingInfo()
        updateWidgetDataIfNeeded(forceReload: true)
    }

    private func handleWake() {
        shouldAutoPlayOnLoad = false
        isPlaying = false
        userWantsPlayback = false

        sleepWakeTask?.cancel()
        sleepWakeTask = Task { [weak self] in
            for _ in 0..<4 {
                if Task.isCancelled { break }
                self?.runJS("""
                window.isSystemSleeping = true;
                if (typeof window.setUserWantsPlayback === 'function') {
                    window.setUserWantsPlayback(false);
                } else {
                    window.userWantsPlayback = false;
                    try { sessionStorage.setItem('__ymacUserWantsPlayback', 'false'); } catch (e) {}
                }
                var v = document.querySelector('video');
                if (v) {
                    if (!v.paused) { v.pause(); }
                    v.muted = true;
                }
                """)
                try? await Task.sleep(nanoseconds: 500_000_000)
            }
            if !Task.isCancelled {
                self?.runJS("""
                window.isSystemSleeping = false;
                if (typeof window.setUserWantsPlayback === 'function') {
                    window.setUserWantsPlayback(false);
                } else {
                    window.userWantsPlayback = false;
                    try { sessionStorage.setItem('__ymacUserWantsPlayback', 'false'); } catch (e) {}
                }
                var v = document.querySelector('video');
                if (v) {
                    if (!v.paused) { v.pause(); }
                    v.muted = true;
                }
                """)
            }
            self?.updateNowPlayingInfo()
            self?.updateWidgetDataIfNeeded(forceReload: true)
        }
    }

    // MARK: - Background Window Management

    func attachToBackgroundWindow() {
        if backgroundWindow == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 1280, height: 800),
                styleMask: [.borderless],
                backing: .buffered,
                defer: false
            )
            window.isReleasedWhenClosed = false
            window.isOpaque = false
            window.backgroundColor = .clear
            window.alphaValue = 0.0
            self.backgroundWindow = window
        }

        if webView.window != backgroundWindow {
            webView.window?.makeFirstResponder(nil)
            webView.translatesAutoresizingMaskIntoConstraints = true
            webView.autoresizingMask = [.width, .height]
            webView.frame = NSRect(x: 0, y: 0, width: 1280, height: 800)
            backgroundWindow?.contentView = webView
            backgroundWindow?.orderBack(nil)
        }
    }

    // MARK: - Navigation Delegate

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let currentURL = webView.url?.absoluteString, currentURL.contains("music.youtube.com") {
            let wantsPlayback = self.userWantsPlayback
            runJS("""
            if (typeof window.setUserWantsPlayback === 'function') {
                window.setUserWantsPlayback(\(wantsPlayback));
            } else {
                window.userWantsPlayback = \(wantsPlayback);
                try { sessionStorage.setItem('__ymacUserWantsPlayback', '\(wantsPlayback ? "true" : "false")'); } catch (e) {}
            }
            var v = document.querySelector('video');
            if (v) {
                if (!window.userWantsPlayback) {
                    if (!v.paused) { v.pause(); }
                    v.muted = true;
                } else {
                    v.muted = false;
                }
            }
            if (typeof window.syncYTM === 'function') { window.syncYTM(true); }
            """)

            if shouldAutoPlayOnLoad && userWantsPlayback {
                if currentURL.contains("watch?v=") {
                    shouldAutoPlayOnLoad = false
                }
                runJS("""
                (function autoPlay() {
                    var count = 0;
                    var clickedPlaylistPlay = false;
                    var interval = setInterval(function() {
                        if (window.isSystemSleeping || !window.userWantsPlayback) {
                            clearInterval(interval);
                            return;
                        }
                        var v = document.querySelector('video');
                        var playBtn = document.querySelector('ytmusic-player-bar #play-pause-button button, ytmusic-miniplayer .ytmusicPlayerControlsPlayPauseButton button, .ytmusicPlayerControlsPlayPauseButton button, #play-pause-button button, #play-pause-button, .play-pause-button');
                        if (v) {
                            v.muted = false;
                            if (v.paused) {
                                var p = v.play();
                                if (p && typeof p.catch === 'function') {
                                    p.catch(function() {
                                        if (playBtn) {
                                            if (typeof window.ymacClick === 'function') { window.ymacClick(playBtn); } else { playBtn.click(); }
                                        }
                                    });
                                }
                                if ((!v.currentSrc && !v.src && v.readyState === 0) && playBtn) {
                                    if (typeof window.ymacClick === 'function') { window.ymacClick(playBtn); } else { playBtn.click(); }
                                }
                            }
                        } else if (playBtn) {
                            if (typeof window.ymacClick === 'function') { window.ymacClick(playBtn); } else { playBtn.click(); }
                        }
                        if (count >= 3 && !clickedPlaylistPlay && (!v || (!v.src && !v.currentSrc) || v.paused)) {
                            var playlistPlayBtn = document.querySelector('ytmusic-responsive-header-renderer ytmusic-play-button-renderer button, ytmusic-playlist-shelf-renderer ytmusic-play-button-renderer button');
                            if (playlistPlayBtn) {
                                clickedPlaylistPlay = true;
                                if (typeof window.ymacClick === 'function') { window.ymacClick(playlistPlayBtn); } else { playlistPlayBtn.click(); }
                            }
                        }
                        if ((v && !v.paused && v.readyState > 1) || count > 25) {
                            clearInterval(interval);
                        }
                        count++;
                    }, 300);
                })();
                """)
            } else if !userWantsPlayback {
                shouldAutoPlayOnLoad = false
            }
        }
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        isPlaying = false
        shouldAutoPlayOnLoad = false
        updateWidgetDataIfNeeded(forceReload: true)
        webView.reload()
    }

    // MARK: - Darwin Notification Listeners

    private func setupDarwinNotificationListeners() {
        let center = CFNotificationCenterGetDarwinNotifyCenter()
        let observer = Unmanaged.passUnretained(self).toOpaque()

        let names = [
            "com.ymacplayer.togglePlay",
            "com.ymacplayer.nextTrack",
            "com.ymacplayer.previousTrack",
            "com.ymacplayer.toggleShuffle",
            "com.ymacplayer.toggleRepeat",
            "com.ymacplayer.selectPlaylist",
            "com.ymacplayer.resetPlaylist"
        ]

        for name in names {
            CFNotificationCenterAddObserver(
                center,
                observer,
                { _, _, name, _, _ in
                    guard let rawName = name?.rawValue as String? else { return }
                    Task { @MainActor in
                        let controller = YTMController.shared
                        switch rawName {
                        case "com.ymacplayer.togglePlay":
                            controller.togglePlay()
                        case "com.ymacplayer.nextTrack":
                            controller.nextTrack()
                        case "com.ymacplayer.previousTrack":
                            controller.previousTrack()
                        case "com.ymacplayer.toggleShuffle":
                            controller.toggleShuffle()
                        case "com.ymacplayer.toggleRepeat":
                            controller.toggleRepeat()
                        case "com.ymacplayer.selectPlaylist":
                            if let playlistID = controller.sharedDefaults?.string(forKey: "pendingSelectedPlaylistID") {
                                let trimmed = playlistID.trimmingCharacters(in: .whitespacesAndNewlines)
                                if !trimmed.isEmpty {
                                    controller.sharedDefaults?.removeObject(forKey: "pendingSelectedPlaylistID")
                                    controller.openPlaylistById(trimmed)
                                }
                            }
                        case "com.ymacplayer.resetPlaylist":
                            controller.resetPlaylistSelection()
                        default:
                            break
                        }
                    }
                },
                name as CFString,
                nil,
                .deliverImmediately
            )
        }
    }

    private func injectJavaScript() {
        let userScript = WKUserScript(
            source: YTMJavaScript.syncScript,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: true
        )
        webView.configuration.userContentController.addUserScript(userScript)
    }

    // MARK: - JavaScript Bridge Handler

    nonisolated func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        Task { @MainActor in
            guard
                message.frameInfo.isMainFrame,
                message.name == "ytmBridge",
                let dictionary = message.body as? [String: Any]
            else { return }

            self.updateQueue(from: dictionary)
            self.updatePlaylists(from: dictionary)

            if let loggedInJS = dictionary["isLoggedIn"] as? Bool {
                let hasPlaylistsOrActive = !self.userPlaylists.isEmpty || self.hasActiveTrack || !self.queue.isEmpty
                let effectiveLoggedIn = loggedInJS || hasPlaylistsOrActive

                if self.isLoggedIn != effectiveLoggedIn {
                    self.isLoggedIn = effectiveLoggedIn
                    self.updateWidgetDataIfNeeded(forceReload: true)
                }
            }

            if let title = dictionary["title"] as? String, !title.isEmpty {
                let cleanTitle = title
                    .replacingOccurrences(of: "YouTube Music", with: "Ymac")
                    .replacingOccurrences(of: "U-Music", with: "Ymac")
                self.currentTitle = cleanTitle
            }

            if let activeBrowserListId = dictionary["currentListId"] as? String {
                let normalizedActiveId = (activeBrowserListId.hasPrefix("VL") && activeBrowserListId.count > 2)
                    ? String(activeBrowserListId.dropFirst(2))
                    : activeBrowserListId

                if !self.pendingPlaylistLoadId.isEmpty && normalizedActiveId == self.pendingPlaylistLoadId {
                    self.pendingPlaylistLoadId = ""
                } else if !self.pendingPlaylistLoadId.isEmpty && Date().timeIntervalSince(self.pendingPlaylistLoadDate) >= 8.0 {
                    self.pendingPlaylistLoadId = ""
                }

                let isPendingGracePeriod = !self.pendingPlaylistLoadId.isEmpty &&
                    self.currentPlaylistId == self.pendingPlaylistLoadId &&
                    Date().timeIntervalSince(self.pendingPlaylistLoadDate) < 8.0

                if !normalizedActiveId.isEmpty && !isPendingGracePeriod {
                    if self.userPlaylists.contains(where: { $0.id == normalizedActiveId }) {
                        if self.currentPlaylistId != normalizedActiveId && (!self.currentPlaylistId.isEmpty || !self.userExplicitlyResetPlaylist) {
                            self.currentPlaylistId = normalizedActiveId
                            self.hasSelectedPlaylist = true
                        }
                    } else if !self.currentPlaylistId.isEmpty && self.currentPlaylistId != normalizedActiveId {
                        self.currentPlaylistId = ""
                    }
                }
            }

            if let playing = dictionary["isPlaying"] as? Bool {
                if playing {
                    self.userWantsPlayback = true
                }
                let effectivePlaying = playing && self.userWantsPlayback
                if self.isPlaying != effectivePlaying {
                    self.isPlaying = effectivePlaying
                }
            }

            if !self.isEditingSlider {
                if let current = (dictionary["currentTime"] as? NSNumber)?.doubleValue, !current.isNaN, !current.isInfinite {
                    self.currentTime = max(0, current)
                }

                if let trackDuration = (dictionary["duration"] as? NSNumber)?.doubleValue, !trackDuration.isNaN, !trackDuration.isInfinite {
                    if trackDuration > 0 || !self.hasActiveTrack {
                        self.duration = max(0, trackDuration)
                    }
                }
            }

            if let artist = dictionary["artist"] as? String {
                if !artist.isEmpty || !self.hasActiveTrack {
                    self.currentArtist = artist
                }
            }

            if let artwork = dictionary["artworkUrl"] as? String {
                if !artwork.isEmpty || !self.hasActiveTrack {
                    self.artworkUrl = artwork
                }
            }

            let now = Date()

            if now.timeIntervalSince(self.lastLikeActionDate) >= 2.5 {
                if let liked = dictionary["isLiked"] as? Bool {
                    self.isLiked = liked
                }

                if let disliked = dictionary["isDisliked"] as? Bool {
                    self.isDisliked = disliked
                }
            }

            if now.timeIntervalSince(self.lastShuffleActionDate) >= 2.5 {
                if let shuffle = dictionary["isShuffle"] as? Bool {
                    self.isShuffle = shuffle
                }
            }

            if now.timeIntervalSince(self.lastRepeatActionDate) >= 2.5 {
                if let mode = (dictionary["repeatMode"] as? NSNumber)?.intValue {
                    self.repeatMode = mode
                }
            }

            self.updateNowPlayingInfo()
            self.updateWidgetDataIfNeeded()
        }
    }

    // MARK: - Widget Synchronization

    private func scheduleWidgetTimelineReload() {
        widgetReloadTask?.cancel()
        widgetReloadTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 150_000_000)
            guard !Task.isCancelled else { return }
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    func updateWidgetDataIfNeeded(forceReload: Bool = false) {
        guard let defaults = sharedDefaults else { return }

        let langRaw = defaults.string(forKey: "widgetLanguage") ?? ""
        let langChanged = langRaw != currentLanguage.rawValue

        let isWidgetActive = hasActiveTrack || hasSelectedPlaylist

        let titleChanged = currentTitle != lastWidgetTitle
        let artistChanged = currentArtist != lastWidgetArtist
        let playStateChanged = isPlaying != lastWidgetIsPlaying
        let shuffleChanged = isShuffle != lastWidgetIsShuffle
        let repeatChanged = repeatMode != lastWidgetRepeatMode
        let loggedInChanged = isLoggedIn != lastWidgetIsLoggedIn
        let playlistSelectedChanged = isWidgetActive != lastWidgetHasSelectedPlaylist
        let durationChanged = abs(duration - lastWidgetDuration) > 0.5
        let playlistsChanged = userPlaylists != lastWidgetPlaylists

        defaults.set(currentTitle, forKey: "widgetTitle")
        defaults.set(currentArtist, forKey: "widgetArtist")
        defaults.set(isPlaying, forKey: "widgetIsPlaying")
        defaults.set(currentTime, forKey: "widgetCurrentTime")
        defaults.set(duration, forKey: "widgetDuration")
        defaults.set(isShuffle, forKey: "widgetIsShuffle")
        defaults.set(repeatMode, forKey: "widgetRepeatMode")
        defaults.set(isLoggedIn, forKey: "widgetIsLoggedIn")
        defaults.set(isWidgetActive, forKey: "widgetHasSelectedPlaylist")
        defaults.set(currentLanguage.rawValue, forKey: "widgetLanguage")
        defaults.set(true, forKey: "widgetIsAppRunning")

        if playlistsChanged || forceReload {
            let playlistDicts = userPlaylists.map { ["id": $0.id, "title": $0.title, "path": $0.path] }
            defaults.set(playlistDicts, forKey: "widgetPlaylists")
            lastWidgetPlaylists = userPlaylists
        }

        if titleChanged || artistChanged || playStateChanged || shuffleChanged || repeatChanged || loggedInChanged || playlistSelectedChanged || durationChanged || langChanged || playlistsChanged || forceReload {
            lastWidgetTitle = currentTitle
            lastWidgetArtist = currentArtist
            lastWidgetIsPlaying = isPlaying
            lastWidgetIsShuffle = isShuffle
            lastWidgetRepeatMode = repeatMode
            lastWidgetIsLoggedIn = isLoggedIn
            lastWidgetHasSelectedPlaylist = isWidgetActive
            lastWidgetDuration = duration

            defaults.synchronize()
            scheduleWidgetTimelineReload()
        }
    }

    private func saveArtworkToAppGroup(image: NSImage) {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "9R2Z2PT297.group.com.ymacplayer"
        ) else { return }

        let fileURL = containerURL.appendingPathComponent("artwork.png")

        if let tiffData = image.tiffRepresentation,
           let bitmap = NSBitmapImageRep(data: tiffData),
           let pngData = bitmap.representation(using: .png, properties: [:]) {
            try? pngData.write(to: fileURL, options: .atomic)
        }
    }

    private func removeArtworkFromAppGroup() {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "9R2Z2PT297.group.com.ymacplayer"
        ) else { return }

        let fileURL = containerURL.appendingPathComponent("artwork.png")
        try? FileManager.default.removeItem(at: fileURL)
    }

    private func updateQueue(from dictionary: [String: Any]) {
        guard let rawQueue = dictionary["queue"] as? [[String: Any]] else { return }

        let parsedQueue = rawQueue.compactMap { item -> YTMQueueItem? in
            guard
                let id = item["id"] as? String,
                let originalIndex = (item["originalIndex"] as? NSNumber)?.intValue,
                let title = item["title"] as? String,
                !title.isEmpty
            else { return nil }

            let artist = item["artist"] as? String ?? ""
            let isSelected = item["isSelected"] as? Bool ?? false

            return YTMQueueItem(
                id: id,
                originalIndex: originalIndex,
                title: title,
                artist: artist,
                isSelected: isSelected
            )
        }

        if !parsedQueue.isEmpty, parsedQueue != queue {
            queue = parsedQueue
        }
    }

    private func updatePlaylists(from dictionary: [String: Any]) {
        guard let rawPlaylists = dictionary["playlists"] as? [[String: Any]] else { return }
        let isLibraryPage = dictionary["isLibraryPage"] as? Bool ?? false

        let playlists = rawPlaylists.compactMap { item -> YTMPlaylist? in
            guard
                let rawId = item["id"] as? String,
                let title = item["title"] as? String,
                let path = item["path"] as? String
            else { return nil }

            let id = (rawId.hasPrefix("VL") && rawId.count > 2) ? String(rawId.dropFirst(2)) : rawId
            return YTMPlaylist(
                id: id,
                title: title,
                path: path
            )
        }

        guard !playlists.isEmpty else { return }

        if libraryFilter == .playlists && !isLibraryPage && !userPlaylists.isEmpty {
            let existingIDs = Set(userPlaylists.map(\.id))
            let newOnes = playlists.filter { !existingIDs.contains($0.id) }
            if !newOnes.isEmpty {
                userPlaylists.append(contentsOf: newOnes)
                updateWidgetDataIfNeeded(forceReload: true)
            }
            return
        }

        if playlists != userPlaylists {
            userPlaylists = playlists
            updateWidgetDataIfNeeded(forceReload: true)
        }
    }

    // MARK: - System Remote Commands

    private func setupRemoteCommands() {
        let commandCenter = MPRemoteCommandCenter.shared()

        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.play() }
            return .success
        }

        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.pause() }
            return .success
        }

        commandCenter.togglePlayPauseCommand.isEnabled = true
        commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.togglePlay() }
            return .success
        }

        commandCenter.nextTrackCommand.isEnabled = true
        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.nextTrack() }
            return .success
        }

        commandCenter.previousTrackCommand.isEnabled = true
        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.previousTrack() }
            return .success
        }

        commandCenter.changePlaybackPositionCommand.isEnabled = true
        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let event = event as? MPChangePlaybackPositionCommandEvent else {
                return .commandFailed
            }

            Task { @MainActor in self?.seekTo(event.positionTime) }
            return .success
        }
    }

    func updateNowPlayingInfo() {
        guard hasActiveTrack else {
            artworkDownloadTask?.cancel()
            artworkDownloadTask = nil
            inFlightArtworkUrl = ""
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            return
        }

        var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [String: Any]()

        nowPlayingInfo[MPMediaItemPropertyTitle] = currentTitle
        nowPlayingInfo[MPMediaItemPropertyArtist] = currentArtist
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0

        if lastLoadedArtworkUrl == artworkUrl, let image = cachedArtworkImage {
            let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
            nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo

        } else if let url = URL(string: artworkUrl), !artworkUrl.isEmpty {
            let targetUrlString = artworkUrl
            cachedArtworkImage = nil
            lastLoadedArtworkUrl = ""
            nowPlayingInfo[MPMediaItemPropertyArtwork] = nil
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo

            if inFlightArtworkUrl != targetUrlString {
                artworkDownloadTask?.cancel()
                inFlightArtworkUrl = targetUrlString
                artworkDownloadTask = Task { [weak self] in
                    defer {
                        if let self = self, self.inFlightArtworkUrl == targetUrlString {
                            self.inFlightArtworkUrl = ""
                        }
                    }

                    guard
                        let (data, _) = try? await URLSession.shared.data(from: url),
                        !Task.isCancelled,
                        let image = NSImage(data: data),
                        let self = self,
                        self.artworkUrl == targetUrlString
                    else { return }

                    self.lastLoadedArtworkUrl = targetUrlString
                    self.cachedArtworkImage = image
                    self.saveArtworkToAppGroup(image: image)

                    var updatedInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [String: Any]()
                    let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
                    updatedInfo[MPMediaItemPropertyArtwork] = artwork

                    MPNowPlayingInfoCenter.default().nowPlayingInfo = updatedInfo
                    self.updateWidgetDataIfNeeded(forceReload: true)
                }
            }
        } else {
            artworkDownloadTask?.cancel()
            artworkDownloadTask = nil
            inFlightArtworkUrl = ""
            cachedArtworkImage = nil
            lastLoadedArtworkUrl = ""
            removeArtworkFromAppGroup()
            nowPlayingInfo[MPMediaItemPropertyArtwork] = nil
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        }
    }

    // MARK: - Settings & Configurations

    func setLanguage(_ language: AppLanguage) {
        currentLanguage = language
        UserDefaults.standard.set(language.rawValue, forKey: "appLanguage")
        updateWidgetDataIfNeeded(forceReload: true)
    }

    func setLibraryFilter(_ filter: LibraryFilter) {
        libraryFilter = filter
        UserDefaults.standard.set(filter.rawValue, forKey: "libraryFilter")

        clearPlaybackState(clearPlaylists: true)

        let targetURL: String
        switch filter {
        case .favoritePlaylists:
            targetURL = "https://music.youtube.com"
        case .playlists:
            targetURL = "https://music.youtube.com/library/playlists"
        }

        if let url = URL(string: targetURL) {
            webView.load(URLRequest(url: url))
        }

        updateWidgetDataIfNeeded(forceReload: true)
    }

    // MARK: - Player State Management

    private func clearPlaybackState(clearPlaylists: Bool) {
        sleepWakeTask?.cancel()
        artworkDownloadTask?.cancel()
        artworkDownloadTask = nil
        inFlightArtworkUrl = ""
        pendingPlaylistLoadId = ""
        pendingPlaylistLoadDate = .distantPast
        lastLikeActionDate = .distantPast
        lastRepeatActionDate = .distantPast
        lastShuffleActionDate = .distantPast

        userWantsPlayback = false
        shouldAutoPlayOnLoad = false
        currentPlaylistId = ""
        hasSelectedPlaylist = false
        isShuffle = false
        repeatMode = 0
        isPlaying = false
        isLiked = false
        isDisliked = false
        currentTime = 0
        duration = 0

        currentTitle = "Ymac Player"
        currentArtist = ""
        artworkUrl = ""

        queue = []
        if clearPlaylists {
            userPlaylists = []
        }

        cachedArtworkImage = nil
        lastLoadedArtworkUrl = ""
        removeArtworkFromAppGroup()

        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil

        runJS("""
        if (typeof window.setUserWantsPlayback === 'function') {
            window.setUserWantsPlayback(false);
        } else {
            window.userWantsPlayback = false;
            try { sessionStorage.setItem('__ymacUserWantsPlayback', 'false'); } catch (e) {}
        }
        var v = document.querySelector('video');
        if (v) {
            if (!v.paused) { v.pause(); }
            v.muted = true;
        }
        window.hasAutoPausedInitial = false;
        """)
    }

    func resetPlaylistSelection() {
        userExplicitlyResetPlaylist = true
        clearPlaybackState(clearPlaylists: false)

        let initialURLString = libraryFilter == .playlists
            ? "https://music.youtube.com/library/playlists"
            : "https://music.youtube.com"
        if let url = URL(string: initialURLString) {
            webView.load(URLRequest(url: url))
        }

        updateWidgetDataIfNeeded(forceReload: true)
    }

    func openPlaylistById(_ playlistID: String) {
        let trimmed = playlistID.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanID = (trimmed.hasPrefix("VL") && trimmed.count > 2) ? String(trimmed.dropFirst(2)) : trimmed
        guard !cleanID.isEmpty else {
            resetPlaylistSelection()
            return
        }

        userExplicitlyResetPlaylist = false
        pendingPlaylistLoadId = cleanID
        pendingPlaylistLoadDate = Date()
        currentPlaylistId = cleanID
        hasSelectedPlaylist = true
        isShuffle = false
        isLiked = false
        isDisliked = false
        currentTime = 0
        duration = 0
        userWantsPlayback = true
        shouldAutoPlayOnLoad = true

        runJS("""
        if (typeof window.setUserWantsPlayback === 'function') {
            window.setUserWantsPlayback(true);
        } else {
            window.userWantsPlayback = true;
            try { sessionStorage.setItem('__ymacUserWantsPlayback', 'true'); } catch (e) {}
        }
        """)

        let encodedID = cleanID.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? cleanID
        let targetURL = "https://music.youtube.com/watch?list=\(encodedID)"

        if let url = URL(string: targetURL) {
            webView.load(URLRequest(url: url))
        }

        updateWidgetDataIfNeeded(forceReload: true)
    }

    // MARK: - JavaScript Interaction Commands

    func runJS(_ script: String) {
        webView.evaluateJavaScript(script, completionHandler: nil)
    }

    func play() {
        if !hasActiveTrack && !hasSelectedPlaylist, let firstPlaylist = userPlaylists.first {
            openPlaylistById(firstPlaylist.id)
            return
        }
        userWantsPlayback = true
        isPlaying = true
        sleepWakeTask?.cancel()
        runJS("""
        window.isSystemSleeping = false;
        if (typeof window.setPlaybackIntent === 'function') {
            window.setPlaybackIntent(true);
        } else {
            window.userWantsPlayback = true;
            try { sessionStorage.setItem('__ymacUserWantsPlayback', 'true'); } catch (e) {}
            var v = document.querySelector('video');
            var playBtn = document.querySelector('ytmusic-player-bar #play-pause-button button, #play-pause-button button, #play-pause-button, .play-pause-button');
            if (v) {
                v.muted = false;
                if (v.paused) {
                    var p = v.play();
                    if (p && typeof p.catch === 'function') {
                        p.catch(function() {
                            if (playBtn) playBtn.click();
                        });
                    }
                    if (typeof window.__playCalls === 'undefined' && !v.currentSrc && !v.src && v.readyState === 0 && playBtn) {
                        playBtn.click();
                    }
                }
            } else if (playBtn) {
                playBtn.click();
            }
        }
        """)
        updateNowPlayingInfo()
        updateWidgetDataIfNeeded(forceReload: true)
    }

    func pause() {
        userWantsPlayback = false
        isPlaying = false
        sleepWakeTask?.cancel()
        runJS("""
        if (typeof window.setPlaybackIntent === 'function') {
            window.setPlaybackIntent(false);
        } else {
            window.userWantsPlayback = false;
            try { sessionStorage.setItem('__ymacUserWantsPlayback', 'false'); } catch (e) {}
            var v = document.querySelector('video');
            if (v) {
                if (!v.paused) { v.pause(); }
                v.muted = true;
            } else {
                var playBtn = document.querySelector('ytmusic-player-bar #play-pause-button button, ytmusic-miniplayer .ytmusicPlayerControlsPlayPauseButton button, .ytmusicPlayerControlsPlayPauseButton button, #play-pause-button button, #play-pause-button, .play-pause-button');
                if (playBtn) playBtn.click();
            }
        }
        """)
        updateNowPlayingInfo()
        updateWidgetDataIfNeeded(forceReload: true)
    }

    func togglePlay() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }

    private func clickPlayerControl(selectors: [String], syncDelaysMs: [Int] = [250, 700]) {
        guard
            let selData = try? JSONSerialization.data(withJSONObject: selectors),
            let selJSON = String(data: selData, encoding: .utf8),
            let delayData = try? JSONSerialization.data(withJSONObject: syncDelaysMs),
            let delayJSON = String(data: delayData, encoding: .utf8)
        else { return }

        let script = """
        (function() {
            var selectors = \(selJSON);
            var delays = \(delayJSON);
            if (typeof window.ymacClickControl === 'function') {
                window.ymacClickControl(selectors);
            } else {
                for (var k = 0; k < selectors.length; k++) {
                    var el2 = document.querySelector(selectors[k]);
                    if (el2) {
                        var btn = (el2.tagName === 'BUTTON' ? el2 : null) || el2.querySelector('button, #button') || el2;
                        if (typeof btn.click === 'function') { btn.click(); }
                        break;
                    }
                }
            }
            delays.forEach(function(ms) {
                setTimeout(function() {
                    if (typeof window.syncYTM === 'function') window.syncYTM(true);
                }, ms);
            });
        })();
        """

        webView.evaluateJavaScript(script) { _, error in
            if let error = error {
                ytmLogger.error("clickPlayerControl JS error: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    func nextTrack() {
        userWantsPlayback = true
        isPlaying = true
        sleepWakeTask?.cancel()
        runJS("""
        window.isSystemSleeping = false;
        if (typeof window.setUserWantsPlayback === 'function') {
            window.setUserWantsPlayback(true);
        } else {
            window.userWantsPlayback = true;
            try { sessionStorage.setItem('__ymacUserWantsPlayback', 'true'); } catch (e) {}
        }
        var v = document.querySelector('video');
        if (v) v.muted = false;
        """)
        clickPlayerControl(selectors: [
            "ytmusic-player-bar .next-button button",
            "ytmusic-player-bar .next-button",
            "ytmusic-player-controls .next-button button",
            "ytmusic-player-controls .next-button",
            "ytmusic-miniplayer .ytmusicPlayerControlsNextButton button",
            "ytmusic-wiz-player-controls .ytmusicPlayerControlsNextButton button",
            ".ytmusicPlayerControlsNextButton button",
            "ytmusic-player-bar [aria-label*='Next' i]",
            "ytmusic-player-bar [aria-label*='Далі' i]",
            "ytmusic-player-bar [aria-label*='Наступн' i]",
            "ytmusic-player-bar [aria-label*='Следующ' i]",
            ".next-button button",
            ".next-button"
        ])
        updateNowPlayingInfo()
        updateWidgetDataIfNeeded(forceReload: true)
    }

    func previousTrack() {
        userWantsPlayback = true
        isPlaying = true
        sleepWakeTask?.cancel()
        runJS("""
        window.isSystemSleeping = false;
        if (typeof window.setUserWantsPlayback === 'function') {
            window.setUserWantsPlayback(true);
        } else {
            window.userWantsPlayback = true;
            try { sessionStorage.setItem('__ymacUserWantsPlayback', 'true'); } catch (e) {}
        }
        var v = document.querySelector('video');
        if (v) v.muted = false;
        """)
        clickPlayerControl(selectors: [
            "ytmusic-player-bar .previous-button button",
            "ytmusic-player-bar .previous-button",
            "ytmusic-player-controls .previous-button button",
            "ytmusic-player-controls .previous-button",
            "ytmusic-miniplayer .ytmusicPlayerControlsPreviousButton button",
            "ytmusic-wiz-player-controls .ytmusicPlayerControlsPreviousButton button",
            ".ytmusicPlayerControlsPreviousButton button",
            "ytmusic-player-bar [aria-label*='Previous' i]",
            "ytmusic-player-bar [aria-label*='Назад' i]",
            "ytmusic-player-bar [aria-label*='Попередн' i]",
            "ytmusic-player-bar [aria-label*='Предыдущ' i]",
            ".previous-button button",
            ".previous-button"
        ])
        updateNowPlayingInfo()
        updateWidgetDataIfNeeded(forceReload: true)
    }

    func playQueueItem(at originalIndex: Int) {
        guard hasActiveTrack, originalIndex >= 0 else { return }
        userWantsPlayback = true
        isPlaying = true
        sleepWakeTask?.cancel()

        runJS(#"""
        (function() {
            window.isSystemSleeping = false;
            if (typeof window.setUserWantsPlayback === 'function') {
                window.setUserWantsPlayback(true);
            } else {
                window.userWantsPlayback = true;
                try { sessionStorage.setItem('__ymacUserWantsPlayback', 'true'); } catch (e) {}
            }
            var v = document.querySelector('video');
            if (v) v.muted = false;

            var idx = \#(originalIndex);
            if (typeof window.ymacPlayQueueIndex === 'function') {
                window.ymacPlayQueueIndex(idx);
                return;
            }

            var queuePanel = document.querySelector('ytmusic-player-queue, #queue, ytmusic-playlist-panel-renderer[is-queue]');
            var elements = [];
            if (queuePanel) {
                elements = Array.from(queuePanel.querySelectorAll('ytmusic-player-queue-item, ytmusic-playlist-panel-video-renderer'));
            }
            if (!elements || elements.length === 0) {
                var mainContents = document.querySelector('#contents.ytmusic-playlist-video-list-renderer, #items.ytmusic-playlist-panel-renderer');
                if (mainContents) {
                    elements = Array.from(mainContents.querySelectorAll('ytmusic-playlist-panel-video-renderer, ytmusic-responsive-list-item-renderer'));
                }
            }
            var validItems = elements.filter(function(item) {
                return !item.hasAttribute('hidden') && !item.closest('[hidden], [aria-hidden="true"], template, ytmusic-player-bar, ytmusic-miniplayer, ytmusic-wiz-player-controls, #player-bar, ytmusic-playlist-header-renderer, #header');
            });
            if (validItems && idx >= 0 && idx < validItems.length && validItems[idx]) {
                var item = validItems[idx];
                var target = item.querySelector('ytmusic-play-button-renderer button, ytmusic-play-button-renderer #button, ytmusic-play-button-renderer, #play-button, .play-button, a, .song-title, .title') || item;
                var button = target.querySelector('button') || target;
                if (typeof button.click === 'function') button.click();
                setTimeout(function() { if (typeof window.syncYTM === 'function') window.syncYTM(true); }, 250);
            }
        })();
        """#)
        updateNowPlayingInfo()
        updateWidgetDataIfNeeded(forceReload: true)
    }

    func likeTrack() {
        guard hasActiveTrack else { return }
        lastLikeActionDate = Date()
        isLiked.toggle()
        if isLiked {
            isDisliked = false
        }
        updateNowPlayingInfo()
        updateWidgetDataIfNeeded(forceReload: true)
        clickPlayerControl(selectors: [
            "ytmusic-player-bar ytmusic-like-button-renderer #button-shape-like button",
            "ytmusic-player-bar ytmusic-like-button-renderer #button-shape-like",
            "ytmusic-miniplayer like-button-view-model button",
            "ytmusic-miniplayer .ytLikeButtonViewModelHost button",
            "like-button-view-model button",
            "ytmusic-like-button-renderer #button-shape-like button",
            "ytmusic-like-button-renderer #button-shape-like",
            "#button-shape-like button",
            "#button-shape-like",
            "ytmusic-like-button-renderer .like button",
            "ytmusic-like-button-renderer .like-button button"
        ])
    }

    func dislikeTrack() {
        guard hasActiveTrack else { return }
        lastLikeActionDate = Date()
        isDisliked.toggle()
        if isDisliked {
            isLiked = false
        }
        updateNowPlayingInfo()
        updateWidgetDataIfNeeded(forceReload: true)
        clickPlayerControl(selectors: [
            "ytmusic-player-bar ytmusic-like-button-renderer #button-shape-dislike button",
            "ytmusic-player-bar ytmusic-like-button-renderer #button-shape-dislike",
            "ytmusic-miniplayer dislike-button-view-model button",
            "ytmusic-miniplayer .ytDislikeButtonViewModelHost button",
            "dislike-button-view-model button",
            "ytmusic-like-button-renderer #button-shape-dislike button",
            "ytmusic-like-button-renderer #button-shape-dislike",
            "#button-shape-dislike button",
            "#button-shape-dislike",
            "ytmusic-like-button-renderer .dislike button",
            "ytmusic-like-button-renderer .dislike-button button"
        ])
    }

    func toggleShuffle() {
        guard hasActiveTrack else { return }
        lastShuffleActionDate = Date()
        isShuffle.toggle()
        updateWidgetDataIfNeeded(forceReload: true)
        clickPlayerControl(
            selectors: [
                "ytmusic-player-bar .right-controls-buttons .shuffle button",
                "ytmusic-player-bar .shuffle button",
                "ytmusic-player-bar .shuffle",
                "ytmusic-player-controls .shuffle button",
                "ytmusic-player-controls .shuffle",
                "ytmusic-miniplayer .ytmusicPlayerControlsShuffleButton button",
                "ytmusic-wiz-player-controls .ytmusicPlayerControlsShuffleButton button",
                ".ytmusicPlayerControlsShuffleButton button",
                ".right-controls-buttons .shuffle button",
                ".right-controls-buttons .shuffle",
                ".shuffle button",
                ".shuffle",
                ".expand-shuffle button",
                ".expand-shuffle",
                ".shuffle-button button",
                ".shuffle-button",
                "[title*='Shuffle' i]",
                "[title*='Переміша' i]",
                "[title*='Перемеша' i]",
                "[aria-label*='Shuffle' i]",
                "[aria-label*='Переміша' i]",
                "[aria-label*='Перемеша' i]"
            ],
            syncDelaysMs: [300, 900, 1600]
        )
    }

    func toggleRepeat() {
        guard hasActiveTrack else { return }
        lastRepeatActionDate = Date()
        repeatMode = (repeatMode + 1) % 3
        updateWidgetDataIfNeeded(forceReload: true)
        clickPlayerControl(
            selectors: [
                "ytmusic-player-bar .right-controls-buttons .repeat button",
                "ytmusic-player-bar .repeat button",
                "ytmusic-player-bar .repeat",
                "ytmusic-player-controls .repeat button",
                "ytmusic-player-controls .repeat",
                "ytmusic-miniplayer .ytmusicPlayerControlsRepeatButton button",
                "ytmusic-wiz-player-controls .ytmusicPlayerControlsRepeatButton button",
                ".ytmusicPlayerControlsRepeatButton button",
                ".right-controls-buttons .repeat button",
                ".right-controls-buttons .repeat",
                ".repeat button",
                ".repeat",
                "#expand-repeat button",
                "#expand-repeat",
                ".repeat-button button",
                ".repeat-button",
                "[title*='Repeat' i]",
                "[title*='Повтор' i]",
                "[aria-label*='Repeat' i]",
                "[aria-label*='Повтор' i]"
            ],
            syncDelaysMs: [200, 600]
        )
    }

    func seekTo(_ time: Double) {
        guard hasActiveTrack, !time.isNaN, !time.isInfinite else { return }
        currentTime = duration > 0 ? min(max(0, time), duration) : max(0, time)

        runJS("""
        var v = document.querySelector('video');
        if (v) { v.currentTime = \(currentTime); }
        """)

        updateNowPlayingInfo()
        updateWidgetDataIfNeeded(forceReload: true)
    }
}
