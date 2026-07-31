import Foundation

// MARK: - Library Filter Categories

/// Defines the category filters available for the user's music library in Ymac Player.
enum LibraryFilter: String, CaseIterable, Identifiable {
    case favoritePlaylists = "favoritePlaylists"
    case playlists = "playlists"

    /// The unique identifier corresponding to the filter raw value.
    var id: String { rawValue }
}
