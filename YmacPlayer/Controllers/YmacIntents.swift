import AppIntents
import WidgetKit
import CoreFoundation

// MARK: - Helper Functions

nonisolated private func canExecuteCommand() -> Bool {
    guard let defaults = UserDefaults(suiteName: "group.com.ymacplayer") else { return true }
    let isLoggedIn = defaults.object(forKey: "widgetIsLoggedIn") != nil ? defaults.bool(forKey: "widgetIsLoggedIn") : true
    let hasSelectedPlaylist = defaults.bool(forKey: "widgetHasSelectedPlaylist")
    return isLoggedIn && hasSelectedPlaylist
}

// MARK: - Playback Control Intents

struct TogglePlayIntent: AppIntent {
    static var title: LocalizedStringResource = "Play / Pause"

    func perform() async throws -> some IntentResult {
        if canExecuteCommand() {
            postDarwinNotification("com.ymacplayer.togglePlay")
        }
        return .result()
    }
}

struct NextTrackIntent: AppIntent {
    static var title: LocalizedStringResource = "Next Track"

    func perform() async throws -> some IntentResult {
        if canExecuteCommand() {
            postDarwinNotification("com.ymacplayer.nextTrack")
        }
        return .result()
    }
}

struct PreviousTrackIntent: AppIntent {
    static var title: LocalizedStringResource = "Previous Track"

    func perform() async throws -> some IntentResult {
        if canExecuteCommand() {
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

        let defaults = UserDefaults(suiteName: "group.com.ymacplayer")
        defaults?.set(cleanID, forKey: "pendingSelectedPlaylistID")
        postDarwinNotification("com.ymacplayer.selectPlaylist")
        return .result()
    }
}

struct ResetPlaylistIntent: AppIntent {
    static var title: LocalizedStringResource = "Reset Playlist Selection"

    func perform() async throws -> some IntentResult {
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
