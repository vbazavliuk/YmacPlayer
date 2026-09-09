import AppIntents
import WidgetKit
import CoreFoundation

// MARK: - Helper Functions

nonisolated private func canExecuteCommand() -> Bool {
    guard let defaults = UserDefaults(suiteName: "group.com.ymacplayer") else { return true }
    let isAppRunning = defaults.bool(forKey: "widgetIsAppRunning")
    guard isAppRunning else { return false }
    let isLoggedIn = defaults.object(forKey: "widgetIsLoggedIn") != nil ? defaults.bool(forKey: "widgetIsLoggedIn") : true
    return isLoggedIn
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
        if canExecuteCommand() {
            if let defaults = UserDefaults(suiteName: "group.com.ymacplayer") {
                let current = defaults.bool(forKey: "widgetIsPlaying")
                defaults.set(!current, forKey: "widgetIsPlaying")
                defaults.synchronize()
            }
            postDarwinNotification("com.ymacplayer.togglePlay")
        }
        return .result()
    }
}

struct NextTrackIntent: AppIntent {
    static var title: LocalizedStringResource = "Next Track"

    func perform() async throws -> some IntentResult {
        if canExecuteCommand() {
            if let defaults = UserDefaults(suiteName: "group.com.ymacplayer") {
                defaults.set(true, forKey: "widgetIsPlaying")
                defaults.synchronize()
            }
            postDarwinNotification("com.ymacplayer.nextTrack")
        }
        return .result()
    }
}

struct PreviousTrackIntent: AppIntent {
    static var title: LocalizedStringResource = "Previous Track"

    func perform() async throws -> some IntentResult {
        if canExecuteCommand() {
            if let defaults = UserDefaults(suiteName: "group.com.ymacplayer") {
                defaults.set(true, forKey: "widgetIsPlaying")
                defaults.synchronize()
            }
            postDarwinNotification("com.ymacplayer.previousTrack")
        }
        return .result()
    }
}

struct ToggleShuffleIntent: AppIntent {
    static var title: LocalizedStringResource = "Shuffle"

    func perform() async throws -> some IntentResult {
        if canExecuteCommand() {
            postDarwinNotification("com.ymacplayer.toggleShuffle")
        }
        return .result()
    }
}

struct ToggleRepeatIntent: AppIntent {
    static var title: LocalizedStringResource = "Repeat"

    func perform() async throws -> some IntentResult {
        if canExecuteCommand() {
            postDarwinNotification("com.ymacplayer.toggleRepeat")
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

        if let defaults = UserDefaults(suiteName: "group.com.ymacplayer") {
            defaults.set(cleanID, forKey: "pendingSelectedPlaylistID")
            defaults.set(true, forKey: "widgetHasSelectedPlaylist")
            defaults.set(true, forKey: "widgetIsPlaying")

            if let rawList = defaults.array(forKey: "widgetPlaylists") as? [[String: String]] {
                if let matched = rawList.first(where: { $0["id"] == cleanID }), let t = matched["title"] {
                    defaults.set(t, forKey: "widgetTitle")
                }
            }
            defaults.synchronize()
        }

        postDarwinNotification("com.ymacplayer.selectPlaylist")
        return .result()
    }
}

struct ResetPlaylistIntent: AppIntent {
    static var title: LocalizedStringResource = "Reset Playlist Selection"

    func perform() async throws -> some IntentResult {
        if let defaults = UserDefaults(suiteName: "group.com.ymacplayer") {
            defaults.set(false, forKey: "widgetHasSelectedPlaylist")
            defaults.set("Ymac Player", forKey: "widgetTitle")
            defaults.set("", forKey: "widgetArtist")
            defaults.set(false, forKey: "widgetIsPlaying")
            defaults.set(0.0, forKey: "widgetCurrentTime")
            defaults.set(0.0, forKey: "widgetDuration")
            defaults.synchronize()
        }

        postDarwinNotification("com.ymacplayer.resetPlaylist")
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
