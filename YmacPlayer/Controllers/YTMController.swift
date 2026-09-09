import SwiftUI
import WebKit
import Combine
import AppKit
import MediaPlayer
import WidgetKit

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
    private var shouldAutoPlayOnLoad: Bool = false
    private var sleepWakeTask: Task<Void, Never>?
    private var artworkDownloadTask: Task<Void, Never>?
    private var sleepObserverTasks: [Task<Void, Never>] = []

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
    private let sharedDefaults = UserDefaults(suiteName: "group.com.ymacplayer")

    private var lastWidgetTitle: String = ""
    private var lastWidgetArtist: String = ""
    private var lastWidgetIsPlaying: Bool = false
    private var lastWidgetIsShuffle: Bool = false
    private var lastWidgetRepeatMode: Int = 0
    private var lastWidgetIsLoggedIn: Bool = true
    private var lastWidgetHasSelectedPlaylist: Bool = false

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

        webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 1000, height: 700), configuration: configuration)
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

        if let url = URL(string: "https://music.youtube.com") {
            webView.load(URLRequest(url: url))
        }
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
        shouldAutoPlayOnLoad = false
        isPlaying = false
        runJS("""
        window.isSystemSleeping = true;
        var v = document.querySelector('video');
        if (v) { v.pause(); }
        """)
        updateWidgetDataIfNeeded(forceReload: true)
    }

    private func handleWake() {
        shouldAutoPlayOnLoad = false
        isPlaying = false

        sleepWakeTask?.cancel()
        sleepWakeTask = Task { [weak self] in
            for _ in 0..<6 {
                if Task.isCancelled { break }
                self?.runJS("""
                window.isSystemSleeping = true;
                var v = document.querySelector('video');
                if (v && !v.paused) { v.pause(); }
                """)
                try? await Task.sleep(nanoseconds: 500_000_000)
            }
            if !Task.isCancelled {
                self?.runJS("window.isSystemSleeping = false;")
            }
            self?.updateWidgetDataIfNeeded(forceReload: true)
        }
    }

    // MARK: - Background Window Management

    func attachToBackgroundWindow() {
        if backgroundWindow == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 1000, height: 700),
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
            backgroundWindow?.contentView = webView
            backgroundWindow?.orderBack(nil)
        }
    }

    // MARK: - Navigation Delegate

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let currentURL = webView.url?.absoluteString, currentURL.contains("music.youtube.com") {
            runJS("if (typeof window.syncYTM === 'function') { window.syncYTM(true); }")

            if shouldAutoPlayOnLoad {
                shouldAutoPlayOnLoad = false
                runJS("""
                (function autoPlay() {
                    var count = 0;
                    var interval = setInterval(function() {
                        if (window.isSystemSleeping) {
                            clearInterval(interval);
                            return;
                        }
                        var v = document.querySelector('video');
                        var playBtn = document.querySelector('#play-pause-button') || document.querySelector('.play-pause-button');
                        if (v && v.paused) {
                            v.play().catch(function() {});
                            if (playBtn) playBtn.click();
                        }
                        if ((v && !v.paused) || count > 25) {
                            clearInterval(interval);
                        }
                        count++;
                    }, 300);
                })();
                """)
            }
        }
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        isPlaying = false
        updateWidgetDataIfNeeded(forceReload: true)
        webView.reload()
    }

    // MARK: - Darwin Notification Listeners

    private func setupDarwinNotificationListeners() {
        let center = CFNotificationCenterGetDarwinNotifyCenter()

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
                nil,
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
                                controller.openPlaylistById(playlistID)
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
            forMainFrameOnly: false
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
                    if !effectiveLoggedIn {
                        self.resetPlaylistSelection()
                    }
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
                if !self.currentPlaylistId.isEmpty && self.currentPlaylistId != activeBrowserListId {
                    self.currentPlaylistId = ""
                }
            }

            if let playing = dictionary["isPlaying"] as? Bool {
                self.isPlaying = playing
            }

            if !self.isEditingSlider {
                if let current = dictionary["currentTime"] as? Double, !current.isNaN, !current.isInfinite {
                    self.currentTime = max(0, current)
                }

                if let trackDuration = dictionary["duration"] as? Double, !trackDuration.isNaN, !trackDuration.isInfinite {
                    self.duration = max(0, trackDuration)
                }
            }

            if let artist = dictionary["artist"] as? String {
                self.currentArtist = artist
            }

            if let artwork = dictionary["artworkUrl"] as? String {
                self.artworkUrl = artwork
            }

            if let liked = dictionary["isLiked"] as? Bool {
                self.isLiked = liked
            }

            if let disliked = dictionary["isDisliked"] as? Bool {
                self.isDisliked = disliked
            }

            if let mode = dictionary["repeatMode"] as? Int {
                self.repeatMode = mode
            }

            self.updateNowPlayingInfo()
            self.updateWidgetDataIfNeeded()
        }
    }

    // MARK: - Widget Synchronization

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

        let playlistDicts = userPlaylists.map { ["id": $0.id, "title": $0.title, "path": $0.path] }
        defaults.set(playlistDicts, forKey: "widgetPlaylists")

        if titleChanged || artistChanged || playStateChanged || shuffleChanged || repeatChanged || loggedInChanged || playlistSelectedChanged || langChanged || forceReload {
            lastWidgetTitle = currentTitle
            lastWidgetArtist = currentArtist
            lastWidgetIsPlaying = isPlaying
            lastWidgetIsShuffle = isShuffle
            lastWidgetRepeatMode = repeatMode
            lastWidgetIsLoggedIn = isLoggedIn
            lastWidgetHasSelectedPlaylist = isWidgetActive

            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    private func saveArtworkToAppGroup(image: NSImage) {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.com.ymacplayer"
        ) else { return }

        let fileURL = containerURL.appendingPathComponent("artwork.png")

        if let tiffData = image.tiffRepresentation,
           let bitmap = NSBitmapImageRep(data: tiffData),
           let pngData = bitmap.representation(using: .png, properties: [:]) {
            try? pngData.write(to: fileURL, options: .atomic)
        }
    }

    private func updateQueue(from dictionary: [String: Any]) {
        guard let rawQueue = dictionary["queue"] as? [[String: Any]] else { return }

        let parsedQueue = rawQueue.compactMap { item -> YTMQueueItem? in
            guard
                let id = item["id"] as? String,
                let originalIndex = item["originalIndex"] as? Int,
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

        if parsedQueue != queue {
            queue = parsedQueue
        }
    }

    private func updatePlaylists(from dictionary: [String: Any]) {
        guard let rawPlaylists = dictionary["playlists"] as? [[String: String]] else { return }

        let playlists = rawPlaylists.compactMap { item -> YTMPlaylist? in
            guard
                let id = item["id"],
                let title = item["title"],
                let path = item["path"]
            else { return nil }

            return YTMPlaylist(
                id: id,
                title: title,
                path: path
            )
        }

        if !playlists.isEmpty, playlists != userPlaylists {
            userPlaylists = playlists
            updateWidgetDataIfNeeded(forceReload: true)
        }
    }

    // MARK: - System Remote Commands

    private func setupRemoteCommands() {
        let commandCenter = MPRemoteCommandCenter.shared()

        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.togglePlay() }
            return .success
        }

        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.togglePlay() }
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
            lastLoadedArtworkUrl = artworkUrl
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo

            artworkDownloadTask?.cancel()
            artworkDownloadTask = Task { [weak self] in
                guard
                    let (data, _) = try? await URLSession.shared.data(from: url),
                    let image = NSImage(data: data)
                else { return }

                if Task.isCancelled { return }

                await MainActor.run { [weak self] in
                    guard let self = self, self.artworkUrl == targetUrlString else { return }

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
            cachedArtworkImage = nil
            lastLoadedArtworkUrl = ""
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

        currentPlaylistId = ""
        hasSelectedPlaylist = false
        isShuffle = false
        repeatMode = 0
        isPlaying = false

        currentTitle = "Ymac Player"
        currentArtist = ""
        artworkUrl = ""

        queue = []
        userPlaylists = []

        cachedArtworkImage = nil
        lastLoadedArtworkUrl = ""

        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil

        runJS("""
        var v = document.querySelector('video');
        if (v) { v.pause(); }
        window.hasAutoPausedInitial = false;
        """)

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

    func resetPlaylistSelection() {
        currentPlaylistId = ""
        hasSelectedPlaylist = false
        isShuffle = false
        repeatMode = 0
        isPlaying = false

        currentTitle = "Ymac Player"
        currentArtist = ""
        artworkUrl = ""

        queue = []

        cachedArtworkImage = nil
        lastLoadedArtworkUrl = ""

        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil

        runJS("""
        var v = document.querySelector('video');
        if (v) { v.pause(); }
        window.hasAutoPausedInitial = false;
        """)

        if let url = URL(string: "https://music.youtube.com") {
            webView.load(URLRequest(url: url))
        }

        updateWidgetDataIfNeeded(forceReload: true)
    }

    func openPlaylistById(_ playlistID: String) {
        let cleanID = playlistID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanID.isEmpty else {
            resetPlaylistSelection()
            return
        }

        currentPlaylistId = cleanID
        hasSelectedPlaylist = true
        isShuffle = false
        shouldAutoPlayOnLoad = true

        let targetURL = "https://music.youtube.com/watch?list=\(cleanID)"

        if let url = URL(string: targetURL) {
            webView.load(URLRequest(url: url))
        }

        updateWidgetDataIfNeeded(forceReload: true)
    }

    // MARK: - JavaScript Interaction Commands

    func runJS(_ script: String) {
        webView.evaluateJavaScript(script, completionHandler: nil)
    }

    func togglePlay() {
        sleepWakeTask?.cancel()
        runJS("""
        window.isSystemSleeping = false;
        var v = document.querySelector('video');
        if (v) {
            v.paused ? v.play() : v.pause();
        } else {
            document.querySelector('#play-pause-button')?.click();
        }
        """)
    }

    func nextTrack() {
        runJS("document.querySelector('.next-button, [aria-label*=\"Next\"]')?.click();")
    }

    func previousTrack() {
        runJS("document.querySelector('.previous-button, [aria-label*=\"Previous\"]')?.click();")
    }

    func playQueueItem(at originalIndex: Int) {
        guard hasActiveTrack, originalIndex >= 0 else { return }

        runJS(#"""
        (function() {
            var getItems = window.getQueueItems || function() {
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
                return elements.filter(function(item) {
                    return !item.closest('ytmusic-player-bar, #player-bar, ytmusic-playlist-header-renderer, #header');
                });
            };

            var validItems = getItems();
            if (validItems && validItems[\#(originalIndex)]) {
                var item = validItems[\#(originalIndex)];
                var target =
                    item.querySelector('ytmusic-play-button-renderer #button') ||
                    item.querySelector('ytmusic-play-button-renderer') ||
                    item.querySelector('#play-button') ||
                    item.querySelector('.play-button') ||
                    item.querySelector('a') ||
                    item.querySelector('.song-title') ||
                    item.querySelector('.title') ||
                    item;

                var button = target.querySelector('button') || target;

                ['pointerdown', 'mousedown', 'pointerup', 'mouseup', 'click'].forEach(function(evtName) {
                    var evt = new MouseEvent(evtName, {
                        bubbles: true,
                        cancelable: true,
                        view: window,
                        composed: true,
                        detail: 1
                    });
                    button.dispatchEvent(evt);
                });

                if (typeof button.click === 'function') {
                    button.click();
                }
            }
        })();
        """#)
    }

    func likeTrack() {
        guard hasActiveTrack else { return }
        runJS("document.querySelector('ytmusic-like-button-renderer #button-shape-like button')?.click();")
    }

    func dislikeTrack() {
        guard hasActiveTrack else { return }
        runJS("document.querySelector('ytmusic-like-button-renderer #button-shape-dislike button')?.click();")
    }

    func toggleShuffle() {
        guard hasActiveTrack else { return }
        isShuffle.toggle()
        updateWidgetDataIfNeeded(forceReload: true)
        runJS("document.querySelector('ytmusic-player-bar .shuffle-button button, ytmusic-player-bar [aria-label*=\"Shuffle\"]')?.click();")
    }

    func toggleRepeat() {
        guard hasActiveTrack else { return }
        repeatMode = (repeatMode + 1) % 3
        updateWidgetDataIfNeeded(forceReload: true)
        runJS("document.querySelector('ytmusic-player-bar .repeat-button button, ytmusic-player-bar [aria-label*=\"Repeat\"]')?.click();")
    }

    func seekTo(_ time: Double) {
        guard hasActiveTrack, !time.isNaN, !time.isInfinite else { return }
        currentTime = max(0, time)

        runJS("""
        var v = document.querySelector('video');
        if (v) { v.currentTime = \(currentTime); }
        """)

        updateNowPlayingInfo()
    }
}
