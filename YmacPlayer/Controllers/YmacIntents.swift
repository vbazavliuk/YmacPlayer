import AppIntents
import WidgetKit
import CoreFoundation

// MARK: - Helper Functions

/// Checks if the app is in a valid state to execute playback commands from widget intents.
/// Marked as `nonisolated` to allow synchronous invocation from non-isolated AppIntent execution contexts in Swift 6.
nonisolated private func canExecuteCommand() -> Bool {
    let defaults = UserDefaults(suiteName: "group.com.ymacplayer")
    let isLoggedIn = defaults?.object(forKey: "widgetIsLoggedIn") != nil ? defaults!.bool(forKey: "widgetIsLoggedIn") : true
    let hasSelectedPlaylist = defaults?.bool(forKey: "widgetHasSelectedPlaylist") ?? false
    return isLoggedIn && hasSelectedPlaylist
}

// MARK: - Playback Control Intents

/// App Intent for toggling playback (Play / Pause).
struct TogglePlayIntent: AppIntent {
    static var title: LocalizedStringResource = "Play / Pause"
    
    func perform() async throws -> some IntentResult {
        if canExecuteCommand() {
            postDarwinNotification("com.ymacplayer.togglePlay")
        }
        return .result()
    }
}

/// App Intent for skipping to the next track.
struct NextTrackIntent: AppIntent {
    static var title: LocalizedStringResource = "Next Track"
    
    func perform() async throws -> some IntentResult {
        if canExecuteCommand() {
            postDarwinNotification("com.ymacplayer.nextTrack")
        }
        return .result()
    }
}

/// App Intent for returning to the previous track.
struct PreviousTrackIntent: AppIntent {
    static var title: LocalizedStringResource = "Previous Track"
    
    func perform() async throws -> some IntentResult {
        if canExecuteCommand() {
            postDarwinNotification("com.ymacplayer.previousTrack")
        }
        return .result()
    }
}

/// App Intent for toggling shuffle mode.
struct ToggleShuffleIntent: AppIntent {
    static var title: LocalizedStringResource = "Shuffle"
    
    func perform() async throws -> some IntentResult {
        if canExecuteCommand() {
            postDarwinNotification("com.ymacplayer.toggleShuffle")
        }
        return .result()
    }
}

/// App Intent for toggling repeat mode.
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

/// App Intent for selecting a playlist via ID.
struct SelectPlaylistIntent: AppIntent {
    static var title: LocalizedStringResource = "Select Playlist"

    @Parameter(title: "Playlist ID")
    var playlistID: String

    init() {}

    init(playlistID: String) {
        self.playlistID = playlistID
    }

    func perform() async throws -> some IntentResult {
        let defaults = UserDefaults(suiteName: "group.com.ymacplayer")
        defaults?.set(playlistID, forKey: "pendingSelectedPlaylistID")
        postDarwinNotification("com.ymacplayer.selectPlaylist")
        return .result()
    }
}

/// App Intent for resetting the active playlist selection.
struct ResetPlaylistIntent: AppIntent {
    static var title: LocalizedStringResource = "Reset Playlist Selection"

    func perform() async throws -> some IntentResult {
        postDarwinNotification("com.ymacplayer.resetPlaylist")
        return .result()
    }
}

// MARK: - Inter-Process Communication

/// Posts a Darwin system notification to trigger player actions across app targets.
nonisolated private func postDarwinNotification(_ name: String) {
    let notificationName = name as CFString
    CFNotificationCenterPostNotification(
        CFNotificationCenterGetDarwinNotifyCenter(),
        CFNotificationName(notificationName),
        nil, nil, true
    )
}
