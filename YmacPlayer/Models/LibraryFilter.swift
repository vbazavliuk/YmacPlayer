import Foundation

// MARK: - Library Filter Categories

/// Defines the category filters available for the user's music library in Ymac Player.
public enum LibraryFilter: String, CaseIterable, Identifiable, Codable, Sendable {
    case favoritePlaylists = "favoritePlaylists"
    case playlists = "playlists"

    /// The unique identifier corresponding to the filter raw value.
    public var id: String { rawValue }
}
