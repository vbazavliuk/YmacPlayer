import AppIntents
import WidgetKit
import CoreFoundation

// MARK: - Helper Functions

nonisolated private let appGroupID = "9R2Z2PT297.group.com.ymacplayer"

nonisolated private func canExecuteCommand() -> Bool {
    guard let defaults = UserDefaults(suiteName: appGroupID) else { return false }
    let isAppRunning = defaults.bool(forKey: "widgetIsAppRunning")
    guard isAppRunning else { return false }
    let isLoggedIn = defaults.object(forKey: "widgetIsLoggedIn") != nil ? defaults.bool(forKey: "widgetIsLoggedIn") : true
    return isLoggedIn
}

/// Executes an optimistic App Group defaults update and posts a Darwin notification
/// only when the main app is running and signed in, then refreshes widget timelines.
nonisolated private func executeIfReady(
    darwinNotification: String,
    updateDefaults: (UserDefaults) -> Void
) {
    if canExecuteCommand() {
        if let defaults = UserDefaults(suiteName: appGroupID) {
            updateDefaults(defaults)
            defaults.synchronize()
        }
        postDarwinNotification(darwinNotification)
    }
    WidgetCenter.shared.reloadAllTimelines()
}

// MARK: - App Launch Intent

struct LaunchAppIntent: AppIntent {
    static var title: LocalizedStringResource = "Launch Ymac Player"
    static var description = IntentDescription("Launches Ymac Player.")
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        return .result()
    }
}

// MARK: - Playback Control Intents

struct TogglePlayIntent: AppIntent {
    static var title: LocalizedStringResource = "Play / Pause"

    func perform() async throws -> some IntentResult {
        executeIfReady(darwinNotification: "com.ymacplayer.togglePlay") { defaults in
            let current = defaults.bool(forKey: "widgetIsPlaying")
            defaults.set(!current, forKey: "widgetIsPlaying")
        }
        return .result()
    }
}

struct NextTrackIntent: AppIntent {
    static var title: LocalizedStringResource = "Next Track"

    func perform() async throws -> some IntentResult {
        executeIfReady(darwinNotification: "com.ymacplayer.nextTrack") { defaults in
            defaults.set(true, forKey: "widgetIsPlaying")
        }
        return .result()
    }
}

struct PreviousTrackIntent: AppIntent {
    static var title: LocalizedStringResource = "Previous Track"

    func perform() async throws -> some IntentResult {
        executeIfReady(darwinNotification: "com.ymacplayer.previousTrack") { defaults in
            defaults.set(true, forKey: "widgetIsPlaying")
        }
        return .result()
    }
}

struct ToggleShuffleIntent: AppIntent {
    static var title: LocalizedStringResource = "Shuffle"

    func perform() async throws -> some IntentResult {
        executeIfReady(darwinNotification: "com.ymacplayer.toggleShuffle") { defaults in
            let current = defaults.bool(forKey: "widgetIsShuffle")
            defaults.set(!current, forKey: "widgetIsShuffle")
        }
        return .result()
    }
}

struct ToggleRepeatIntent: AppIntent {
    static var title: LocalizedStringResource = "Repeat"

    func perform() async throws -> some IntentResult {
        executeIfReady(darwinNotification: "com.ymacplayer.toggleRepeat") { defaults in
            let current = defaults.integer(forKey: "widgetRepeatMode")
            let normalized = (0...2).contains(current) ? current : 0
            defaults.set((normalized + 1) % 3, forKey: "widgetRepeatMode")
        }
        return .result()
    }
}

// MARK: - Playlist Management Intents

struct SelectPlaylistIntent: AppIntent {
    static var title: LocalizedStringResource = "Select Playlist"

    @Parameter(title: "Playlist ID")
    var playlistID: String

    init() {}

    init(playlistID: String) {
        self.playlistID = playlistID
    }

    func perform() async throws -> some IntentResult {
        let cleanID = playlistID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanID.isEmpty else { return .result() }

        executeIfReady(darwinNotification: "com.ymacplayer.selectPlaylist") { defaults in
            defaults.set(cleanID, forKey: "pendingSelectedPlaylistID")
            defaults.set(true, forKey: "widgetHasSelectedPlaylist")
            defaults.set(true, forKey: "widgetIsPlaying")
            defaults.set(false, forKey: "widgetIsShuffle")

            if let rawList = defaults.array(forKey: "widgetPlaylists") as? [[String: String]],
               let matched = rawList.first(where: { $0["id"] == cleanID }),
               let title = matched["title"]?.trimmingCharacters(in: .whitespacesAndNewlines),
               !title.isEmpty {
                defaults.set(title, forKey: "widgetTitle")
            }
        }
        return .result()
    }
}

struct ResetPlaylistIntent: AppIntent {
    static var title: LocalizedStringResource = "Reset Playlist Selection"

    func perform() async throws -> some IntentResult {
        executeIfReady(darwinNotification: "com.ymacplayer.resetPlaylist") { defaults in
            defaults.removeObject(forKey: "pendingSelectedPlaylistID")
            defaults.set(false, forKey: "widgetHasSelectedPlaylist")
            defaults.set("Ymac Player", forKey: "widgetTitle")
            defaults.set("", forKey: "widgetArtist")
            defaults.set(false, forKey: "widgetIsPlaying")
            defaults.set(false, forKey: "widgetIsShuffle")
            defaults.set(0, forKey: "widgetRepeatMode")
            defaults.set(0.0, forKey: "widgetCurrentTime")
            defaults.set(0.0, forKey: "widgetDuration")
        }
        return .result()
    }
}

// MARK: - Inter-Process Communication

nonisolated private func postDarwinNotification(_ name: String) {
    let notificationName = name as CFString
    CFNotificationCenterPostNotification(
        CFNotificationCenterGetDarwinNotifyCenter(),
        CFNotificationName(notificationName),
        nil, nil, true
    )
}
