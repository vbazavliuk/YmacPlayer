import Foundation

// MARK: - Playlist & Queue Data Models

/// Represents a user playlist in Ymac Player.
struct YTMPlaylist: Identifiable, Hashable {
    /// The unique identifier of the playlist (e.g., YouTube Music playlist ID).
    let id: String
    
    /// The localized display title of the playlist.
    let title: String
    
    /// The relative or absolute URL path to the playlist.
    let path: String
}

/// Represents an individual track within the active playback queue.
struct YTMQueueItem: Identifiable, Hashable {
    /// The unique identifier for the queue item.
    let id: String
    
    /// The original zero-based index of the item within the raw Web Queue.
    let originalIndex: Int
    
    /// The track title.
    let title: String
    
    /// The artist or contributor name.
    let artist: String
    
    /// Indicates whether this track is currently selected or playing.
    let isSelected: Bool
}
