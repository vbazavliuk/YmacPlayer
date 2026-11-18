import Foundation

// MARK: - Core Domain Models

public struct YTMPlaylist: Identifiable, Hashable, Codable, Sendable {
    public let id: String
    public let title: String
    public let path: String

    public init(id: String, title: String, path: String) {
        self.id = id
        self.title = title
        self.path = path
    }
}

public struct YTMQueueItem: Identifiable, Hashable, Codable, Sendable {
    public let id: String
    public let originalIndex: Int
    public let title: String
    public let artist: String
    public let isSelected: Bool

    public init(
        id: String,
        originalIndex: Int,
        title: String,
        artist: String,
        isSelected: Bool
    ) {
        self.id = id
        self.originalIndex = originalIndex
        self.title = title
        self.artist = artist
        self.isSelected = isSelected
    }
}

public struct PlayerSnapshot: Equatable, Codable, Sendable {
    public let title: String
    public let artist: String
    public let isPlaying: Bool
    public let currentTime: Double
    public let duration: Double
    public let isShuffle: Bool
    public let repeatMode: Int
    public let isLoggedIn: Bool
    public let hasSelectedPlaylist: Bool
    public let language: String
    public let playlists: [YTMPlaylist]

    public init(
        title: String,
        artist: String,
        isPlaying: Bool,
        currentTime: Double,
        duration: Double,
        isShuffle: Bool,
        repeatMode: Int,
        isLoggedIn: Bool,
        hasSelectedPlaylist: Bool,
        language: String,
        playlists: [YTMPlaylist]
    ) {
        self.title = title
        self.artist = artist
        self.isPlaying = isPlaying
        self.currentTime = currentTime
        self.duration = duration
        self.isShuffle = isShuffle
        self.repeatMode = repeatMode
        self.isLoggedIn = isLoggedIn
        self.hasSelectedPlaylist = hasSelectedPlaylist
        self.language = language
        self.playlists = playlists
    }
}
