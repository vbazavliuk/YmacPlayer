import Foundation

#if TEST_APP
import AppKit
import SwiftUI
import WebKit
#elseif TEST_WIDGET
import AppIntents
import SwiftUI
import WidgetKit
#endif

// MARK: - Minimal Zero-Dependency Test Harness

@MainActor
private final class TestSuite {
    let name: String
    private(set) var passed = 0
    private(set) var failed = 0

    init(name: String) {
        self.name = name
        print("==> Running \(name)")
    }

    func section(_ title: String) {
        print("  [Section] \(title)")
    }

    func assert(
        _ condition: @autoclosure () -> Bool,
        _ message: String,
        file: String = #fileID,
        line: Int = #line
    ) {
        if condition() {
            passed += 1
        } else {
            failed += 1
            print("  FAIL [\(file):\(line)] \(message)")
        }
    }

    func assertEqual<T: Equatable>(
        _ actual: T,
        _ expected: T,
        _ message: String,
        file: String = #fileID,
        line: Int = #line
    ) {
        if actual == expected {
            passed += 1
        } else {
            failed += 1
            print("  FAIL [\(file):\(line)] \(message) — expected: \(expected), actual: \(actual)")
        }
    }

    func assertApprox(
        _ actual: Double,
        _ expected: Double,
        tolerance: Double = 0.001,
        _ message: String,
        file: String = #fileID,
        line: Int = #line
    ) {
        if !actual.isNaN && !actual.isInfinite && abs(actual - expected) <= tolerance {
            passed += 1
        } else {
            failed += 1
            print("  FAIL [\(file):\(line)] \(message) — expected ~\(expected) (±\(tolerance)), actual: \(actual)")
        }
    }

    func printSummary() -> Int {
        print("==> \(name): \(passed) passed, \(failed) failed")
        return failed
    }
}

// MARK: - UserDefaults & App Group Snapshot / Cleanup

private enum SavedDefaultsValue {
    case absent
    case present(Any)
}

@MainActor
private final class DefaultsBackup {
    static let appGroupSuite = "9R2Z2PT297.group.com.ymacplayer"

    private static let standardKeys = [
        "appLanguage",
        "libraryFilter"
    ]

    private static let sharedKeys = [
        "widgetTitle",
        "widgetArtist",
        "widgetIsPlaying",
        "widgetCurrentTime",
        "widgetDuration",
        "widgetIsShuffle",
        "widgetRepeatMode",
        "widgetIsLoggedIn",
        "widgetHasSelectedPlaylist",
        "widgetLanguage",
        "widgetIsAppRunning",
        "widgetPlaylists",
        "pendingSelectedPlaylistID"
    ]

    private var savedStandard: [String: SavedDefaultsValue] = [:]
    private var savedShared: [String: SavedDefaultsValue] = [:]
    private var artworkExistedBefore = false
    private var savedArtworkData: Data?

    func capture() {
        let standard = UserDefaults.standard
        for key in Self.standardKeys {
            if let value = standard.object(forKey: key) {
                savedStandard[key] = .present(value)
            } else {
                savedStandard[key] = .absent
            }
        }

        if let shared = UserDefaults(suiteName: Self.appGroupSuite) {
            for key in Self.sharedKeys {
                if let value = shared.object(forKey: key) {
                    savedShared[key] = .present(value)
                } else {
                    savedShared[key] = .absent
                }
            }
        }

        if let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: Self.appGroupSuite
        ) {
            let fileURL = containerURL.appendingPathComponent("artwork.png")
            if FileManager.default.fileExists(atPath: fileURL.path) {
                artworkExistedBefore = true
                savedArtworkData = try? Data(contentsOf: fileURL)
            }
        }
    }

    func restore() {
        let standard = UserDefaults.standard
        for (key, value) in savedStandard {
            switch value {
            case .absent:
                standard.removeObject(forKey: key)
            case .present(let obj):
                standard.set(obj, forKey: key)
            }
        }
        standard.synchronize()

        if let shared = UserDefaults(suiteName: Self.appGroupSuite) {
            for (key, value) in savedShared {
                switch value {
                case .absent:
                    shared.removeObject(forKey: key)
                case .present(let obj):
                    shared.set(obj, forKey: key)
                }
            }
            shared.synchronize()
        }

        if let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: Self.appGroupSuite
        ) {
            let fileURL = containerURL.appendingPathComponent("artwork.png")
            if artworkExistedBefore, let data = savedArtworkData {
                try? data.write(to: fileURL, options: .atomic)
            } else if !artworkExistedBefore, FileManager.default.fileExists(atPath: fileURL.path) {
                try? FileManager.default.removeItem(at: fileURL)
            }
        }
    }
}

// MARK: - Shared Tests (Models & Localization)

@MainActor
private func runModelsAndCodableTests(_ suite: TestSuite) {
    suite.section("Models & Codable")

    let encoder = JSONEncoder()
    let decoder = JSONDecoder()

    // YTMPlaylist
    let playlist1 = YTMPlaylist(id: "PL_01", title: "Chill Beats", path: "playlist?list=PL_01")
    let playlist1Copy = YTMPlaylist(id: "PL_01", title: "Chill Beats", path: "playlist?list=PL_01")
    let playlist2 = YTMPlaylist(id: "LM", title: "Liked Music", path: "playlist?list=LM")
    suite.assertEqual(playlist1, playlist1Copy, "YTMPlaylist Hashable/Equatable matches identical items")
    suite.assert(playlist1 != playlist2, "YTMPlaylist inequality works")
    suite.assertEqual(Set([playlist1, playlist1Copy, playlist2]).count, 2, "YTMPlaylist Set deduplication")
    suite.assertEqual(playlist1.id, "PL_01", "YTMPlaylist Identifiable id")

    do {
        let encoded = try encoder.encode([playlist1, playlist2])
        let decoded = try decoder.decode([YTMPlaylist].self, from: encoded)
        suite.assertEqual(decoded, [playlist1, playlist2], "YTMPlaylist Codable round-trip")
    } catch {
        suite.assert(false, "YTMPlaylist Codable threw: \(error)")
    }

    // YTMQueueItem
    let qItem1 = YTMQueueItem(id: "q_0_Echoes", originalIndex: 0, title: "Echoes", artist: "Artist A", isSelected: false)
    let qItem2 = YTMQueueItem(id: "q_2_Echoes", originalIndex: 2, title: "Echoes", artist: "Artist A", isSelected: true)
    suite.assert(qItem1 != qItem2, "YTMQueueItem with identical title at different indices remain distinct")
    suite.assertEqual(Set([qItem1, qItem2]).count, 2, "YTMQueueItem Set keeps distinct positions")
    suite.assertEqual(qItem2.id, "q_2_Echoes", "YTMQueueItem Identifiable id")
    suite.assertEqual(qItem2.originalIndex, 2, "YTMQueueItem originalIndex preserved")

    do {
        let encoded = try encoder.encode([qItem1, qItem2])
        let decoded = try decoder.decode([YTMQueueItem].self, from: encoded)
        suite.assertEqual(decoded, [qItem1, qItem2], "YTMQueueItem Codable round-trip")
    } catch {
        suite.assert(false, "YTMQueueItem Codable threw: \(error)")
    }

    // PlayerSnapshot (Codable + Equatable)
    let snapshotA = PlayerSnapshot(
        title: "Midnight City",
        artist: "M83",
        isPlaying: true,
        currentTime: 42.5,
        duration: 243.0,
        isShuffle: true,
        repeatMode: 1,
        isLoggedIn: true,
        hasSelectedPlaylist: true,
        language: "en",
        playlists: [playlist1, playlist2]
    )
    let snapshotB = PlayerSnapshot(
        title: "Midnight City",
        artist: "M83",
        isPlaying: true,
        currentTime: 42.5,
        duration: 243.0,
        isShuffle: true,
        repeatMode: 1,
        isLoggedIn: true,
        hasSelectedPlaylist: true,
        language: "en",
        playlists: [playlist1, playlist2]
    )
    let snapshotDifferent = PlayerSnapshot(
        title: "Outro",
        artist: "M83",
        isPlaying: false,
        currentTime: 10.0,
        duration: 243.0,
        isShuffle: false,
        repeatMode: 2,
        isLoggedIn: true,
        hasSelectedPlaylist: true,
        language: "de",
        playlists: [playlist1]
    )

    suite.assertEqual(snapshotA, snapshotB, "PlayerSnapshot Equatable matches identical snapshots")
    suite.assert(snapshotA != snapshotDifferent, "PlayerSnapshot Equatable distinguishes different snapshots")

    do {
        let encoded = try encoder.encode(snapshotA)
        let decoded = try decoder.decode(PlayerSnapshot.self, from: encoded)
        suite.assertEqual(decoded, snapshotA, "PlayerSnapshot Codable round-trip")
    } catch {
        suite.assert(false, "PlayerSnapshot Codable threw: \(error)")
    }

    // LibraryFilter (Codable, CaseIterable, Identifiable)
    suite.assertEqual(LibraryFilter.allCases.count, 2, "LibraryFilter has 2 cases")
    suite.assert(LibraryFilter.allCases.contains(.favoritePlaylists), "LibraryFilter contains favoritePlaylists")
    suite.assert(LibraryFilter.allCases.contains(.playlists), "LibraryFilter contains playlists")
    for filter in LibraryFilter.allCases {
        suite.assertEqual(filter.id, filter.rawValue, "LibraryFilter.id matches rawValue for \(filter)")
    }
    do {
        let encoded = try encoder.encode(LibraryFilter.allCases)
        let decoded = try decoder.decode([LibraryFilter].self, from: encoded)
        suite.assertEqual(decoded, LibraryFilter.allCases, "LibraryFilter Codable round-trip")
    } catch {
        suite.assert(false, "LibraryFilter Codable threw: \(error)")
    }

    // AppLanguage
    suite.assertEqual(AppLanguage.allCases.count, 10, "AppLanguage has 10 supported languages")
    let expectedCodes = Set(["en", "de", "ru", "uk", "es", "pt", "it", "fr", "ro", "pl"])
    suite.assertEqual(Set(AppLanguage.allCases.map(\.rawValue)), expectedCodes, "AppLanguage covers all 10 language codes")
    for lang in AppLanguage.allCases {
        suite.assertEqual(lang.id, lang.rawValue, "AppLanguage.id matches rawValue for \(lang.rawValue)")
        suite.assert(!lang.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, "AppLanguage.title non-empty for \(lang.rawValue)")
    }
}

@MainActor
private func runLocalizationCompletenessTests(_ suite: TestSuite) {
    suite.section("Localization Completeness (all 10 languages)")

    func isNonEmpty(_ s: String) -> Bool {
        !s.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    for lang in AppLanguage.allCases {
        let code = lang.rawValue
        suite.assert(isNonEmpty(LocalizedStrings.pleaseSignIn(lang)), "pleaseSignIn non-empty for \(code)")
        suite.assert(isNonEmpty(LocalizedStrings.selectPlaylist(lang)), "selectPlaylist non-empty for \(code)")
        suite.assert(isNonEmpty(LocalizedStrings.loadingPlaylists(lang)), "loadingPlaylists non-empty for \(code)")
        suite.assert(isNonEmpty(LocalizedStrings.selectPlaylistPrompt(lang)), "selectPlaylistPrompt non-empty for \(code)")

        let collapseHelp = LocalizedStrings.toggleViewHelp(lang, showFull: true)
        let expandHelp = LocalizedStrings.toggleViewHelp(lang, showFull: false)
        suite.assert(isNonEmpty(collapseHelp), "toggleViewHelp(true) non-empty for \(code)")
        suite.assert(isNonEmpty(expandHelp), "toggleViewHelp(false) non-empty for \(code)")
        suite.assert(collapseHelp != expandHelp, "toggleViewHelp differs for true vs false in \(code)")

        suite.assert(isNonEmpty(LocalizedStrings.languageMenuTitle(lang)), "languageMenuTitle non-empty for \(code)")
        suite.assert(isNonEmpty(LocalizedStrings.libraryMenuTitle(lang)), "libraryMenuTitle non-empty for \(code)")
        suite.assert(isNonEmpty(LocalizedStrings.favoritePlaylistsCategoryTitle(lang)), "favoritePlaylistsCategoryTitle non-empty for \(code)")
        suite.assert(isNonEmpty(LocalizedStrings.playlistsCategoryTitle(lang)), "playlistsCategoryTitle non-empty for \(code)")
        suite.assert(isNonEmpty(LocalizedStrings.autostartMenuTitle(lang)), "autostartMenuTitle non-empty for \(code)")
        suite.assert(isNonEmpty(LocalizedStrings.aboutMenuTitle(lang)), "aboutMenuTitle non-empty for \(code)")
        suite.assert(isNonEmpty(LocalizedStrings.quitApp(lang)), "quitApp non-empty for \(code)")
        suite.assert(isNonEmpty(LocalizedStrings.upNext(lang)), "upNext non-empty for \(code)")
        suite.assert(isNonEmpty(LocalizedStrings.emptyQueue(lang)), "emptyQueue non-empty for \(code)")

        let playing = LocalizedStrings.playing(lang)
        let paused = LocalizedStrings.paused(lang)
        suite.assert(isNonEmpty(playing), "playing non-empty for \(code)")
        suite.assert(isNonEmpty(paused), "paused non-empty for \(code)")
        suite.assert(playing != paused, "playing != paused for \(code)")

        suite.assert(isNonEmpty(LocalizedStrings.launchPlayer(lang)), "launchPlayer non-empty for \(code)")
        suite.assert(isNonEmpty(LocalizedStrings.appNotRunning(lang)), "appNotRunning non-empty for \(code)")

        // New localization helpers
        suite.assert(isNonEmpty(LocalizedStrings.backButton(lang)), "backButton non-empty for \(code)")
        suite.assert(isNonEmpty(LocalizedStrings.loginButton(lang)), "loginButton non-empty for \(code)")
        suite.assert(isNonEmpty(LocalizedStrings.shuffleHelp(lang)), "shuffleHelp non-empty for \(code)")

        let repeat0 = LocalizedStrings.repeatHelp(lang, mode: 0)
        let repeat1 = LocalizedStrings.repeatHelp(lang, mode: 1)
        let repeat2 = LocalizedStrings.repeatHelp(lang, mode: 2)
        suite.assert(isNonEmpty(repeat0), "repeatHelp(mode: 0) non-empty for \(code)")
        suite.assert(isNonEmpty(repeat1), "repeatHelp(mode: 1) non-empty for \(code)")
        suite.assert(isNonEmpty(repeat2), "repeatHelp(mode: 2) non-empty for \(code)")
        suite.assert(Set([repeat0, repeat1, repeat2]).count == 3, "repeatHelp modes 0/1/2 distinct for \(code)")

        suite.assert(isNonEmpty(LocalizedStrings.likeHelp(lang)), "likeHelp non-empty for \(code)")
        suite.assert(isNonEmpty(LocalizedStrings.dislikeHelp(lang)), "dislikeHelp non-empty for \(code)")
        suite.assert(isNonEmpty(LocalizedStrings.queueHelp(lang)), "queueHelp non-empty for \(code)")

        let aboutDesc = LocalizedStrings.aboutDescription(lang)
        suite.assert(isNonEmpty(aboutDesc), "aboutDescription non-empty for \(code)")
        suite.assert(aboutDesc.count >= 20, "aboutDescription is substantive for \(code)")
    }

    // Ensure new strings are actually localized across languages rather than single-language stubs
    suite.assert(Set(AppLanguage.allCases.map { LocalizedStrings.backButton($0) }).count >= 5, "backButton localized across languages")
    suite.assert(Set(AppLanguage.allCases.map { LocalizedStrings.loginButton($0) }).count >= 5, "loginButton localized across languages")
    suite.assert(Set(AppLanguage.allCases.map { LocalizedStrings.shuffleHelp($0) }).count >= 5, "shuffleHelp localized across languages")
    suite.assert(Set(AppLanguage.allCases.map { LocalizedStrings.likeHelp($0) }).count >= 5, "likeHelp localized across languages")
    suite.assert(Set(AppLanguage.allCases.map { LocalizedStrings.dislikeHelp($0) }).count >= 5, "dislikeHelp localized across languages")
    suite.assert(Set(AppLanguage.allCases.map { LocalizedStrings.queueHelp($0) }).count >= 5, "queueHelp localized across languages")
    suite.assert(Set(AppLanguage.allCases.map { LocalizedStrings.aboutDescription($0) }).count >= 5, "aboutDescription localized across languages")
}

// MARK: - App Target Tests

#if TEST_APP

@MainActor
private func runAppFormatTimeTests(_ suite: TestSuite) {
    suite.section("App formatTime edge cases")

    suite.assertEqual(formatTime(0), "0:00", "formatTime(0)")
    suite.assertEqual(formatTime(-5), "0:00", "formatTime(-5)")
    suite.assertEqual(formatTime(Double.nan), "0:00", "formatTime(NaN)")
    suite.assertEqual(formatTime(Double.infinity), "0:00", "formatTime(+Inf)")
    suite.assertEqual(formatTime(-Double.infinity), "0:00", "formatTime(-Inf)")
    suite.assertEqual(formatTime(59), "0:59", "formatTime(59)")
    suite.assertEqual(formatTime(60), "1:00", "formatTime(60)")
    suite.assertEqual(formatTime(3599), "59:59", "formatTime(3599)")
    suite.assertEqual(formatTime(3600), "1:00:00", "formatTime(3600)")
    suite.assertEqual(formatTime(3661), "1:01:01", "formatTime(3661)")
}

@MainActor
private func pumpRunLoop(seconds: TimeInterval) async {
    let deadline = Date().addingTimeInterval(seconds)
    while Date() < deadline {
        try? await Task.sleep(nanoseconds: 20_000_000)
    }
}

@MainActor
private func waitUntil(timeout: TimeInterval = 5.0, _ condition: () -> Bool) async -> Bool {
    let deadline = Date().addingTimeInterval(timeout)
    while Date() < deadline {
        if condition() {
            return true
        }
        try? await Task.sleep(nanoseconds: 20_000_000)
    }
    return condition()
}

@MainActor
private func evaluateJS(_ webView: WKWebView, _ script: String) async throws -> Any? {
    try await withCheckedThrowingContinuation { continuation in
        webView.evaluateJavaScript(script) { result, error in
            if let error {
                continuation.resume(throwing: error)
            } else {
                continuation.resume(returning: result)
            }
        }
    }
}

@MainActor
private func runYTMControllerStateAndDefaultsTests(_ suite: TestSuite) async {
    suite.section("YTMController state & Widget Defaults sync")

    let controller = YTMController.shared
    controller.webView.stopLoading()
    let sharedDefaults = UserDefaults(suiteName: DefaultsBackup.appGroupSuite)

    // hasActiveTrack edge cases
    controller.currentTitle = "Ymac Player"
    suite.assertEqual(controller.hasActiveTrack, false, "hasActiveTrack false for 'Ymac Player'")
    controller.currentTitle = ""
    suite.assertEqual(controller.hasActiveTrack, false, "hasActiveTrack false for empty string")
    controller.currentTitle = "Ymac"
    suite.assertEqual(controller.hasActiveTrack, false, "hasActiveTrack false for 'Ymac'")
    controller.currentTitle = "YouTube Music"
    suite.assertEqual(controller.hasActiveTrack, false, "hasActiveTrack false for 'YouTube Music'")
    controller.currentTitle = "Starlight"
    suite.assertEqual(controller.hasActiveTrack, true, "hasActiveTrack true for real song title")

    // setLanguage + UserDefaults sync
    controller.setLanguage(.ukrainian)
    suite.assertEqual(controller.currentLanguage, .ukrainian, "setLanguage updates currentLanguage")
    suite.assertEqual(UserDefaults.standard.string(forKey: "appLanguage"), "uk", "setLanguage persists appLanguage")
    suite.assertEqual(sharedDefaults?.string(forKey: "widgetLanguage"), "uk", "setLanguage syncs widgetLanguage")

    controller.setLanguage(.english)
    suite.assertEqual(controller.currentLanguage, .english, "setLanguage restores English")
    suite.assertEqual(sharedDefaults?.string(forKey: "widgetLanguage"), "en", "setLanguage syncs widgetLanguage back to en")

    // openPlaylistById & whitespace reset
    controller.openPlaylistById("  PL_STATE_TEST  ")
    controller.webView.stopLoading()
    suite.assertEqual(controller.currentPlaylistId, "PL_STATE_TEST", "openPlaylistById trims whitespace")
    suite.assertEqual(controller.hasSelectedPlaylist, true, "openPlaylistById sets hasSelectedPlaylist")
    suite.assertEqual(controller.isShuffle, false, "openPlaylistById resets isShuffle")
    suite.assertEqual(controller.userWantsPlayback, true, "openPlaylistById sets userWantsPlayback")
    suite.assertEqual(sharedDefaults?.bool(forKey: "widgetHasSelectedPlaylist"), true, "openPlaylistById syncs widgetHasSelectedPlaylist")

    controller.openPlaylistById("   ")
    controller.webView.stopLoading()
    suite.assertEqual(controller.currentPlaylistId, "", "openPlaylistById with empty/whitespace resets currentPlaylistId")
    suite.assertEqual(controller.hasSelectedPlaylist, false, "openPlaylistById with whitespace clears hasSelectedPlaylist")
    suite.assertEqual(controller.userWantsPlayback, false, "openPlaylistById with whitespace clears userWantsPlayback")

    // Guards when !hasActiveTrack
    controller.currentTitle = "Ymac Player"
    controller.isLiked = false
    controller.isDisliked = false
    controller.isShuffle = false
    controller.repeatMode = 0
    controller.currentTime = 0

    controller.likeTrack()
    suite.assertEqual(controller.isLiked, false, "likeTrack is no-op when !hasActiveTrack")
    controller.dislikeTrack()
    suite.assertEqual(controller.isDisliked, false, "dislikeTrack is no-op when !hasActiveTrack")
    controller.toggleShuffle()
    suite.assertEqual(controller.isShuffle, false, "toggleShuffle is no-op when !hasActiveTrack")
    controller.toggleRepeat()
    suite.assertEqual(controller.repeatMode, 0, "toggleRepeat is no-op when !hasActiveTrack")
    controller.seekTo(50)
    suite.assertApprox(controller.currentTime, 0, "seekTo is no-op when !hasActiveTrack")

    // Optimistic like/dislike, shuffle, repeat, seek when hasActiveTrack
    controller.currentTitle = "Active Track"
    controller.currentArtist = "Active Artist"
    controller.duration = 210

    controller.likeTrack()
    suite.assertEqual(controller.isLiked, true, "likeTrack optimistically sets isLiked = true")
    suite.assertEqual(controller.isDisliked, false, "likeTrack keeps isDisliked = false")

    controller.dislikeTrack()
    suite.assertEqual(controller.isDisliked, true, "dislikeTrack optimistically sets isDisliked = true")
    suite.assertEqual(controller.isLiked, false, "dislikeTrack clears isLiked = false")

    controller.dislikeTrack()
    suite.assertEqual(controller.isDisliked, false, "second dislikeTrack toggles isDisliked off")

    controller.likeTrack()
    suite.assertEqual(controller.isLiked, true, "likeTrack sets isLiked = true again")
    controller.likeTrack()
    suite.assertEqual(controller.isLiked, false, "second likeTrack toggles isLiked off")

    // Shuffle & App Group sync
    controller.toggleShuffle()
    suite.assertEqual(controller.isShuffle, true, "toggleShuffle flips false -> true")
    suite.assertEqual(sharedDefaults?.bool(forKey: "widgetIsShuffle"), true, "toggleShuffle syncs widgetIsShuffle = true")
    controller.toggleShuffle()
    suite.assertEqual(controller.isShuffle, false, "toggleShuffle flips true -> false")
    suite.assertEqual(sharedDefaults?.bool(forKey: "widgetIsShuffle"), false, "toggleShuffle syncs widgetIsShuffle = false")

    // Repeat & App Group sync
    controller.toggleRepeat()
    suite.assertEqual(controller.repeatMode, 1, "toggleRepeat cycles 0 -> 1")
    suite.assertEqual(sharedDefaults?.integer(forKey: "widgetRepeatMode"), 1, "toggleRepeat syncs widgetRepeatMode = 1")
    controller.toggleRepeat()
    suite.assertEqual(controller.repeatMode, 2, "toggleRepeat cycles 1 -> 2")
    suite.assertEqual(sharedDefaults?.integer(forKey: "widgetRepeatMode"), 2, "toggleRepeat syncs widgetRepeatMode = 2")
    controller.toggleRepeat()
    suite.assertEqual(controller.repeatMode, 0, "toggleRepeat cycles 2 -> 0")
    suite.assertEqual(sharedDefaults?.integer(forKey: "widgetRepeatMode"), 0, "toggleRepeat syncs widgetRepeatMode = 0")

    // seekTo & App Group sync
    controller.seekTo(45.5)
    suite.assertApprox(controller.currentTime, 45.5, "seekTo updates currentTime")
    suite.assertApprox(sharedDefaults?.double(forKey: "widgetCurrentTime") ?? -1, 45.5, "seekTo syncs widgetCurrentTime immediately")
    controller.seekTo(Double.nan)
    suite.assertApprox(controller.currentTime, 45.5, "seekTo ignores NaN")
    controller.seekTo(Double.infinity)
    suite.assertApprox(controller.currentTime, 45.5, "seekTo ignores Infinity")
    controller.seekTo(-12.0)
    suite.assertApprox(controller.currentTime, 0.0, "seekTo clamps negative seek to 0")

    // durationChanged widget sync even with forceReload: false
    controller.duration = 0
    controller.updateWidgetDataIfNeeded(forceReload: false)
    suite.assertApprox(sharedDefaults?.double(forKey: "widgetDuration") ?? -1, 0.0, "widgetDuration syncs to 0")
    controller.duration = 185.0
    controller.updateWidgetDataIfNeeded(forceReload: false)
    suite.assertApprox(sharedDefaults?.double(forKey: "widgetDuration") ?? -1, 185.0, "durationChanged updates widgetDuration without forceReload")

    // resetPlaylistSelection clears full state and defaults
    controller.currentPlaylistId = "PL_DIRTY"
    controller.hasSelectedPlaylist = true
    controller.isShuffle = true
    controller.repeatMode = 2
    controller.isPlaying = true
    controller.isLiked = true
    controller.isDisliked = false
    controller.currentTime = 80
    controller.duration = 200
    controller.artworkUrl = "https://example.com/art.jpg"
    controller.queue = [YTMQueueItem(id: "q_0_A", originalIndex: 0, title: "A", artist: "B", isSelected: true)]

    controller.resetPlaylistSelection()
    controller.webView.stopLoading()

    suite.assertEqual(controller.hasActiveTrack, false, "resetPlaylistSelection clears hasActiveTrack")
    suite.assertEqual(controller.currentTitle, "Ymac Player", "resetPlaylistSelection resets currentTitle")
    suite.assertEqual(controller.currentArtist, "", "resetPlaylistSelection clears currentArtist")
    suite.assertEqual(controller.artworkUrl, "", "resetPlaylistSelection clears artworkUrl")
    suite.assertEqual(controller.currentPlaylistId, "", "resetPlaylistSelection clears currentPlaylistId")
    suite.assertEqual(controller.hasSelectedPlaylist, false, "resetPlaylistSelection clears hasSelectedPlaylist")
    suite.assertEqual(controller.isShuffle, false, "resetPlaylistSelection resets isShuffle")
    suite.assertEqual(controller.repeatMode, 0, "resetPlaylistSelection resets repeatMode")
    suite.assertEqual(controller.isPlaying, false, "resetPlaylistSelection resets isPlaying")
    suite.assertEqual(controller.isLiked, false, "resetPlaylistSelection resets isLiked")
    suite.assertEqual(controller.isDisliked, false, "resetPlaylistSelection resets isDisliked")
    suite.assertApprox(controller.currentTime, 0, "resetPlaylistSelection resets currentTime")
    suite.assertApprox(controller.duration, 0, "resetPlaylistSelection resets duration")
    suite.assert(controller.queue.isEmpty, "resetPlaylistSelection empties queue")

    suite.assertEqual(sharedDefaults?.string(forKey: "widgetTitle"), "Ymac Player", "widgetTitle reset in defaults")
    suite.assertEqual(sharedDefaults?.string(forKey: "widgetArtist"), "", "widgetArtist reset in defaults")
    suite.assertEqual(sharedDefaults?.bool(forKey: "widgetIsPlaying"), false, "widgetIsPlaying reset in defaults")
    suite.assertEqual(sharedDefaults?.bool(forKey: "widgetHasSelectedPlaylist"), false, "widgetHasSelectedPlaylist reset in defaults")
    suite.assertApprox(sharedDefaults?.double(forKey: "widgetCurrentTime") ?? -1, 0, "widgetCurrentTime reset in defaults")
    suite.assertApprox(sharedDefaults?.double(forKey: "widgetDuration") ?? -1, 0, "widgetDuration reset in defaults")
    suite.assertEqual(sharedDefaults?.bool(forKey: "widgetIsAppRunning"), true, "widgetIsAppRunning remains true")

    // setLibraryFilter syncs filter & clears active playback state
    controller.currentTitle = "Temp Track"
    controller.currentTime = 30
    controller.duration = 120
    controller.isLiked = true
    controller.setLibraryFilter(.playlists)
    controller.webView.stopLoading()
    suite.assertEqual(controller.libraryFilter, .playlists, "setLibraryFilter updates libraryFilter")
    suite.assertEqual(UserDefaults.standard.string(forKey: "libraryFilter"), "playlists", "setLibraryFilter persists libraryFilter")
    suite.assertEqual(controller.hasActiveTrack, false, "setLibraryFilter clears active track")
    suite.assertApprox(controller.currentTime, 0, "setLibraryFilter resets currentTime")
    suite.assertApprox(controller.duration, 0, "setLibraryFilter resets duration")
    suite.assertEqual(controller.isLiked, false, "setLibraryFilter resets isLiked")

    controller.setLibraryFilter(.favoritePlaylists)
    controller.webView.stopLoading()
}

// MARK: - Live WKWebView + YTMJavaScript.syncScript Integration Tests

@MainActor
private final class BridgeSpy: NSObject, WKScriptMessageHandler {
    var payloads: [[String: Any]] = []

    nonisolated func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        Task { @MainActor in
            guard message.name == "ytmBridge", let dict = message.body as? [String: Any] else { return }
            self.payloads.append(dict)
        }
    }
}

private func buildMockYTMHTML(loggedIn: Bool = true) -> String {
    let longPlaylistTitle = "Extended Playlist Name Over Sixty Characters Long To Verify The New 120 Character Limit" // 87 chars
    let authMarkup = loggedIn
        ? #"<ytmusic-avatar-button id="avatar-btn"></ytmusic-avatar-button>"#
        : #"<a href="https://accounts.google.com/ServiceLogin">Sign in</a>"#

    let libraryAndQueueMarkup = loggedIn ? """
      <div id="sections">
        <ytmusic-guide-section-renderer>
          <ytmusic-guide-entry-renderer>
            <a href="playlist?list=PL_SHORT_01">Chill Mix</a>
          </ytmusic-guide-entry-renderer>
          <ytmusic-guide-entry-renderer>
            <a href="playlist?list=PL_LONG_87">\(longPlaylistTitle)</a>
          </ytmusic-guide-entry-renderer>
          <ytmusic-guide-entry-renderer>
            <a href="playlist?list=LM">Liked Music</a>
          </ytmusic-guide-entry-renderer>
          <ytmusic-guide-entry-renderer>
            <a href="playlist?list=SE">Saved Episodes</a>
          </ytmusic-guide-entry-renderer>
          <ytmusic-guide-entry-renderer>
            <a href="playlist?list=RDCLAK5uy_test123">Top Hits Mix</a>
          </ytmusic-guide-entry-renderer>
          <ytmusic-guide-entry-renderer>
            <a href="watch?v=abc123&amp;list=RD999">Radio Station</a>
          </ytmusic-guide-entry-renderer>
          <ytmusic-guide-entry-renderer>
            <a href="playlist?list=PL_HOME">Home</a>
          </ytmusic-guide-entry-renderer>
        </ytmusic-guide-section-renderer>
      </div>

      <ytmusic-player-queue>
        <ytmusic-player-queue-item>
          <yt-formatted-string class="song-title">Same Song</yt-formatted-string>
          <yt-formatted-string class="byline">Band One</yt-formatted-string>
        </ytmusic-player-queue-item>
        <ytmusic-player-queue-item>
          <yt-formatted-string class="song-title">Interlude</yt-formatted-string>
          <yt-formatted-string class="byline">Band Two</yt-formatted-string>
        </ytmusic-player-queue-item>
        <ytmusic-player-queue-item selected>
          <yt-formatted-string class="song-title">Same Song</yt-formatted-string>
          <yt-formatted-string class="byline">Band Three</yt-formatted-string>
        </ytmusic-player-queue-item>
      </ytmusic-player-queue>
    """ : ""

    return """
    <!doctype html>
    <html>
    <head><meta charset="utf-8"><title>YouTube Music Mock</title></head>
    <body>
      <video id="mock-video"></video>
      <tp-yt-paper-icon-button id="button">Decoy Button</tp-yt-paper-icon-button>
      \(authMarkup)

      <ytmusic-player-bar>
        <div class="middle-controls">
          <yt-formatted-string class="title" title="Same Song">Same Song</yt-formatted-string>
          <yt-formatted-string class="byline" title="Band Three">Band Three</yt-formatted-string>
          <img class="image" src="https://lh3.googleusercontent.com/cover=w120-h120-l90-rj" />
        </div>
        <ytmusic-like-button-renderer id="like-renderer" like-status="LIKE">
          <div id="button-shape-like"><button aria-pressed="false">Like</button></div>
          <div id="button-shape-dislike"><button aria-pressed="false">Dislike</button></div>
        </ytmusic-like-button-renderer>
        <yt-icon-button class="previous-button"><button>Prev</button></yt-icon-button>
        <button id="play-pause-button">Play/Pause</button>
        <yt-icon-button class="next-button"><button>Next</button></yt-icon-button>
        <tp-yt-paper-icon-button class="shuffle" aria-pressed="true">Shuffle</tp-yt-paper-icon-button>
        <tp-yt-paper-icon-button class="repeat" aria-label="Repeat all" aria-pressed="true">Repeat</tp-yt-paper-icon-button>
      </ytmusic-player-bar>

      \(libraryAndQueueMarkup)

      <script>
        (function() {
          window.__playCalls = 0;
          window.__pauseCalls = 0;
          window.__playBtnClicks = 0;
          window.__decoyBtnClicks = 0;
          window.__mockPaused = true;
          window.__mockCurrentTime = 42.5;
          window.__mockDuration = 245.0;

          const v = document.getElementById('mock-video');
          Object.defineProperty(v, 'paused', { get: () => window.__mockPaused, configurable: true });
          Object.defineProperty(v, 'ended', { get: () => false, configurable: true });
          Object.defineProperty(v, 'readyState', { get: () => 4, configurable: true });
          Object.defineProperty(v, 'duration', { get: () => window.__mockDuration, configurable: true });
          Object.defineProperty(v, 'currentTime', {
            get: () => window.__mockCurrentTime,
            set: (val) => { window.__mockCurrentTime = Number(val); },
            configurable: true
          });

          v.play = function() {
            window.__playCalls++;
            window.__mockPaused = false;
            v.dispatchEvent(new Event('play'));
            return Promise.resolve();
          };

          v.pause = function() {
            window.__pauseCalls++;
            window.__mockPaused = true;
            v.dispatchEvent(new Event('pause'));
          };

          document.getElementById('play-pause-button').addEventListener('click', function() {
            window.__playBtnClicks++;
            window.__mockPaused = !window.__mockPaused;
          });

          document.getElementById('button').addEventListener('click', function() {
            window.__decoyBtnClicks++;
          });

          document.documentElement.dataset.mockReady = '1';
        })();
      </script>
    </body>
    </html>
    """
}

@MainActor
private func loadHTMLAndWait(_ webView: WKWebView, html: String, baseURL: URL) async -> Bool {
    webView.stopLoading()
    webView.loadHTMLString(html, baseURL: baseURL)

    let deadline = Date().addingTimeInterval(5.0)
    while Date() < deadline {
        if !webView.isLoading {
            if let ready = try? await evaluateJS(webView, "document.documentElement && document.documentElement.dataset.mockReady === '1'") as? Bool,
               ready {
                return true
            }
        }
        try? await Task.sleep(nanoseconds: 20_000_000)
    }
    return false
}

@MainActor
private func runWKWebViewJSIntegrationTests(_ suite: TestSuite) async {
    suite.section("Live WKWebView + YTMJavaScript.syncScript integration")

    // Part A: Isolated WKWebView + BridgeSpy inspecting raw bridge payloads & JS behavior
    let spy = BridgeSpy()
    let config = WKWebViewConfiguration()
    config.mediaTypesRequiringUserActionForPlayback = []
    config.userContentController.add(spy, name: "ytmBridge")

    let spyWebView = WKWebView(frame: CGRect(x: 0, y: 0, width: 1000, height: 700), configuration: config)
    let loaded = await loadHTMLAndWait(
        spyWebView,
        html: buildMockYTMHTML(loggedIn: true),
        baseURL: URL(string: "https://music.youtube.com/watch?list=PL_LIVE_99")!
    )
    suite.assert(loaded, "Mock YTM HTML loaded into WKWebView")

    // Evaluate YTMJavaScript.syncScript directly and trigger syncYTM(true)
    do {
        _ = try await evaluateJS(spyWebView, YTMJavaScript.syncScript)
        _ = try await evaluateJS(spyWebView, "window.syncYTM(true);")
    } catch {
        suite.assert(false, "Failed to evaluate YTMJavaScript.syncScript: \(error)")
    }

    let gotPayload = await waitUntil(timeout: 3.0) { !spy.payloads.isEmpty }
    suite.assert(gotPayload, "BridgeSpy received initial payload from YTMJavaScript.syncScript")

    if let payload = spy.payloads.last {
        suite.assertEqual(payload["isLoggedIn"] as? Bool, true, "Bridge payload isLoggedIn == true")
        suite.assertEqual(payload["title"] as? String, "Same Song", "Bridge payload title")
        suite.assertEqual(payload["artist"] as? String, "Band Three", "Bridge payload artist")
        let art = payload["artworkUrl"] as? String ?? ""
        suite.assert(art.contains("=w512-h512-l90-rj"), "Bridge payload upgrades artwork URL to 512px")
        suite.assertEqual(payload["isLiked"] as? Bool, true, "Bridge payload detects like-status='LIKE'")
        suite.assertEqual(payload["isDisliked"] as? Bool, false, "Bridge payload isDisliked == false")
        suite.assertEqual(payload["repeatMode"] as? Int, 1, "Bridge payload repeatMode == 1")
        suite.assertEqual(payload["isShuffle"] as? Bool, true, "Bridge payload detects isShuffle == true")
        suite.assertEqual(payload["currentListId"] as? String, "PL_LIVE_99", "Bridge payload parses currentListId")
        suite.assertApprox(payload["currentTime"] as? Double ?? -1, 42.5, "Bridge payload currentTime")
        suite.assertApprox(payload["duration"] as? Double ?? -1, 245.0, "Bridge payload duration")

        // Queue extraction: identical titles in different positions preserved & activeDomIdx accurate
        let queue = payload["queue"] as? [[String: Any]] ?? []
        suite.assertEqual(queue.count, 3, "Queue preserves tracks with identical titles in different positions")
        if queue.count == 3 {
            suite.assertEqual(queue[0]["title"] as? String, "Same Song", "Queue[0] title")
            suite.assertEqual(queue[0]["originalIndex"] as? Int, 0, "Queue[0] originalIndex")
            suite.assertEqual(queue[0]["isSelected"] as? Bool, false, "Queue[0] isSelected == false")
            suite.assertEqual(queue[1]["title"] as? String, "Interlude", "Queue[1] title")
            suite.assertEqual(queue[2]["title"] as? String, "Same Song", "Queue[2] title")
            suite.assertEqual(queue[2]["originalIndex"] as? Int, 2, "Queue[2] originalIndex")
            suite.assertEqual(queue[2]["isSelected"] as? Bool, true, "Queue[2] isSelected == true")
        }

        // Playlist extraction (including 60..119 char title and list=SE)
        let playlists = payload["playlists"] as? [[String: Any]] ?? []
        let playlistIDs = playlists.compactMap { $0["id"] as? String }
        suite.assert(playlistIDs.contains("PL_SHORT_01"), "Playlists include PL_SHORT_01")
        suite.assert(playlistIDs.contains("PL_LONG_87"), "Playlists include 87-char title PL_LONG_87 (60..119 chars)")
        suite.assert(playlistIDs.contains("LM"), "Playlists include LM")
        suite.assert(playlistIDs.contains("SE"), "Playlists include SE")
        suite.assert(playlistIDs.contains("RDCLAK5uy_test123"), "Playlists include RDCLAK mix")
        suite.assert(!playlistIDs.contains("RD999"), "Playlists exclude radio watch?v=...&list=RD999")
        suite.assert(!playlistIDs.contains("PL_HOME"), "Playlists exclude ignoreTerm 'Home'")
    }

    // Verify decoy generic #button was NOT clicked by hasTriggeredGuide
    let decoyClicks = (try? await evaluateJS(spyWebView, "window.__decoyBtnClicks")) as? Int ?? -1
    suite.assertEqual(decoyClicks, 0, "hasTriggeredGuide does NOT click generic tp-yt-paper-icon-button#button")

    // Duplicate injection guard
    _ = try? await evaluateJS(spyWebView, YTMJavaScript.syncScript)
    let guardFlag = (try? await evaluateJS(spyWebView, "window.__ymacSyncInitialized === true")) as? Bool ?? false
    suite.assertEqual(guardFlag, true, "window.__ymacSyncInitialized guard is active after duplicate injection")

    // timeupdate throttling (>= 500ms) — run early before 1800ms setInterval fires
    spy.payloads.removeAll()
    _ = try? await evaluateJS(spyWebView, """
    (function() {
      window.__lastTimeUpdateSync = 0;
      const v = document.getElementById('mock-video');
      for (let i = 0; i < 5; i++) {
        v.dispatchEvent(new Event('timeupdate'));
      }
    })();
    """)
    await pumpRunLoop(seconds: 0.15)
    suite.assertEqual(spy.payloads.count, 1, "5 rapid timeupdate events throttle to 1 bridge message")

    await pumpRunLoop(seconds: 0.55)
    spy.payloads.removeAll()
    _ = try? await evaluateJS(spyWebView, "document.getElementById('mock-video').dispatchEvent(new Event('timeupdate'));")
    let receivedAfterWindow = await waitUntil(timeout: 1.5) { !spy.payloads.isEmpty }
    suite.assert(receivedAfterWindow, "timeupdate emits again after >= 500ms throttle window")

    // Test DISLIKE, like-status="INDIFFERENT" + aria-pressed="true", repeatMode 0 & 2, isShuffle state
    spy.payloads.removeAll()
    _ = try? await evaluateJS(spyWebView, """
    (function() {
      const like = document.getElementById('like-renderer');
      like.setAttribute('like-status', 'DISLIKE');
      const shuffle = document.querySelector('ytmusic-player-bar .shuffle');
      shuffle.setAttribute('aria-pressed', 'false');
      shuffle.classList.remove('active');
      const rep = document.querySelector('ytmusic-player-bar .repeat');
      rep.setAttribute('aria-pressed', 'false');
      rep.setAttribute('aria-label', 'Repeat off');
      rep.innerHTML = 'Repeat';
      window.syncYTM(true);
    })();
    """)
    _ = await waitUntil(timeout: 2.0) { !spy.payloads.isEmpty }
    if let p = spy.payloads.last {
        suite.assertEqual(p["isLiked"] as? Bool, false, "DISLIKE clears isLiked")
        suite.assertEqual(p["isDisliked"] as? Bool, true, "like-status='DISLIKE' sets isDisliked == true")
        suite.assertEqual(p["repeatMode"] as? Int, 0, "repeatMode == 0 when off")
        suite.assertEqual(p["isShuffle"] as? Bool, false, "isShuffle == false when aria-pressed='false'")
    } else {
        suite.assert(false, "Missing payload for DISLIKE / repeatMode 0")
    }

    // Verify like-status="INDIFFERENT" with inner aria-pressed="true" still detects isLiked == true
    spy.payloads.removeAll()
    _ = try? await evaluateJS(spyWebView, """
    (function() {
      const like = document.getElementById('like-renderer');
      like.setAttribute('like-status', 'INDIFFERENT');
      like.querySelector('#button-shape-like button').setAttribute('aria-pressed', 'true');
      const shuffle = document.querySelector('ytmusic-player-bar .shuffle');
      shuffle.setAttribute('aria-pressed', 'true');
      window.syncYTM(true);
    })();
    """)
    _ = await waitUntil(timeout: 2.0) { !spy.payloads.isEmpty }
    if let p = spy.payloads.last {
        suite.assertEqual(p["isLiked"] as? Bool, true, "like-status='INDIFFERENT' with aria-pressed='true' detects isLiked == true")
        suite.assertEqual(p["isDisliked"] as? Bool, false, "isDisliked == false when liked via aria-pressed")
        suite.assertEqual(p["isShuffle"] as? Bool, true, "isShuffle == true when shuffle aria-pressed='true'")
    } else {
        suite.assert(false, "Missing payload for INDIFFERENT + aria-pressed='true'")
    }

    // Verify window.ymacClick dispatches single click to inner button & shadowRoot, ymacStepQueue steps cleanly, and setUserWantsPlayback persists
    let clickAndStepOK = (try? await evaluateJS(spyWebView, """
    (function() {
      const host = document.createElement('tp-yt-paper-icon-button');
      const inner = document.createElement('button');
      let events = [];
      ['pointerdown', 'mousedown', 'pointerup', 'mouseup', 'click'].forEach(ev => {
        inner.addEventListener(ev, () => events.push(ev));
      });
      host.appendChild(inner);
      document.body.appendChild(host);
      const okLight = window.ymacClick(host);

      const shadowHost = document.createElement('div');
      const sr = shadowHost.attachShadow({ mode: 'open' });
      const srBtn = document.createElement('button');
      let srClicks = 0;
      srBtn.addEventListener('click', () => srClicks++);
      sr.appendChild(srBtn);
      document.body.appendChild(shadowHost);
      const okShadow = window.ymacClick(shadowHost);

      const items = window.getQueueItems();
      let steppedToIdx1 = false;
      items[1].addEventListener('click', () => { steppedToIdx1 = true; });
      const didStepBack = window.ymacStepQueue(-1);
      const didStepForwardOutOfBounds = window.ymacStepQueue(1);

      window.setUserWantsPlayback(true);
      const persistedTrue = sessionStorage.getItem('__ymacUserWantsPlayback') === 'true' && window.userWantsPlayback === true;
      window.setUserWantsPlayback(false);
      const persistedFalse = sessionStorage.getItem('__ymacUserWantsPlayback') === 'false' && window.userWantsPlayback === false;

      host.remove();
      shadowHost.remove();
      return okLight && okShadow && events.join(',') === 'click' && srClicks === 1 && didStepBack === true && steppedToIdx1 === true && didStepForwardOutOfBounds === false && persistedTrue && persistedFalse;
    })();
    """)) as? Bool ?? false
    suite.assert(clickAndStepOK, "window.ymacClick fires single click without double-toggle, ymacStepQueue steps linearly, and setUserWantsPlayback persists")

    spy.payloads.removeAll()
    _ = try? await evaluateJS(spyWebView, """
    (function() {
      const rep = document.querySelector('ytmusic-player-bar .repeat');
      rep.setAttribute('aria-pressed', 'true');
      rep.setAttribute('aria-label', 'Repeat one');
      rep.innerHTML = '<svg><path id="repeat_one"></path></svg>';
      window.syncYTM(true);
    })();
    """)
    _ = await waitUntil(timeout: 2.0) { !spy.payloads.isEmpty }
    if let p = spy.payloads.last {
        suite.assertEqual(p["repeatMode"] as? Int, 2, "repeatMode == 2 for repeat_one")
    } else {
        suite.assert(false, "Missing payload for repeatMode 2")
    }

    // Test repeatMode detection via aria-label across all 10 supported languages (including offTokens precedence)
    let localizedRepeatLabels: [(String, Int)] = [
        ("Repeat all off", 0), ("Повтор вимкнено", 0), ("Повтор всех выключен", 0),
        ("Repeat all", 1), ("Repeat one", 2),
        ("Alle wiederholen", 1), ("Einen Titel wiederholen", 2),
        ("Повторять все", 1), ("Повторять одну композицию", 2),
        ("Повтор усіх", 1), ("Повторювати одну пісню", 2),
        ("Repetir todo", 1), ("Repetir una canción", 2),
        ("Repetir tudo", 1), ("Repetir uma música", 2),
        ("Ripeti tutto", 1), ("Ripeti un brano", 2),
        ("Tout répéter", 1), ("Répéter un titre", 2),
        ("Repetă tot", 1), ("Repetă o melodie", 2),
        ("Powtarzaj wszystko", 1), ("Powtarzaj jeden utwór", 2)
    ]
    for (label, expectedMode) in localizedRepeatLabels {
        spy.payloads.removeAll()
        let escapedLabel = label.replacingOccurrences(of: "'", with: "\\'")
        _ = try? await evaluateJS(spyWebView, """
        (function() {
          const rep = document.querySelector('ytmusic-player-bar .repeat');
          rep.removeAttribute('repeat-mode');
          rep.removeAttribute('data-repeat-mode');
          rep.setAttribute('aria-pressed', 'false');
          rep.setAttribute('aria-label', '\(escapedLabel)');
          rep.innerHTML = 'Repeat';
          window.syncYTM(true);
        })();
        """)
        let gotLocalized = await waitUntil(timeout: 1.5) { !spy.payloads.isEmpty }
        suite.assert(gotLocalized, "Received payload for repeat label '\(label)'")
        suite.assertEqual(spy.payloads.last?["repeatMode"] as? Int, expectedMode, "repeatMode == \(expectedMode) for '\(label)'")
    }

    // setPlaybackIntent(true/false) NO double-toggle check
    _ = try? await evaluateJS(spyWebView, """
    window.__playCalls = 0;
    window.__pauseCalls = 0;
    window.__playBtnClicks = 0;
    window.__mockPaused = true;
    window.setPlaybackIntent(true);
    """)
    await pumpRunLoop(seconds: 0.1)
    let spyPausedAfterPlay = (try? await evaluateJS(spyWebView, "document.getElementById('mock-video').paused")) as? Bool ?? true
    let spyPlayCalls = (try? await evaluateJS(spyWebView, "window.__playCalls")) as? Int ?? 0
    let spyPlayBtnClicksAfterPlay = (try? await evaluateJS(spyWebView, "window.__playBtnClicks")) as? Int ?? -1
    suite.assertEqual(spyPausedAfterPlay, false, "setPlaybackIntent(true) unpauses video")
    suite.assertEqual(spyPlayCalls, 1, "setPlaybackIntent(true) calls video.play() once")
    suite.assertEqual(spyPlayBtnClicksAfterPlay, 0, "setPlaybackIntent(true) does NOT double-toggle #play-pause-button")

    _ = try? await evaluateJS(spyWebView, "window.setPlaybackIntent(false);")
    await pumpRunLoop(seconds: 0.1)
    let spyPausedAfterPause = (try? await evaluateJS(spyWebView, "document.getElementById('mock-video').paused")) as? Bool ?? false
    let spyMutedAfterPause = (try? await evaluateJS(spyWebView, "document.getElementById('mock-video').muted")) as? Bool ?? false
    let spyPauseCalls = (try? await evaluateJS(spyWebView, "window.__pauseCalls")) as? Int ?? 0
    let spyPlayBtnClicksAfterPause = (try? await evaluateJS(spyWebView, "window.__playBtnClicks")) as? Int ?? -1
    suite.assertEqual(spyPausedAfterPause, true, "setPlaybackIntent(false) pauses video without double-toggling")
    suite.assertEqual(spyMutedAfterPause, true, "setPlaybackIntent(false) mutes video")
    suite.assertEqual(spyPauseCalls, 1, "setPlaybackIntent(false) calls video.pause() once")
    suite.assertEqual(spyPlayBtnClicksAfterPause, 0, "setPlaybackIntent(false) does NOT click #play-pause-button")

    // Logged-out detection test
    let loggedOutSpy = BridgeSpy()
    let loggedOutConfig = WKWebViewConfiguration()
    loggedOutConfig.userContentController.add(loggedOutSpy, name: "ytmBridge")
    let loggedOutWebView = WKWebView(frame: CGRect(x: 0, y: 0, width: 800, height: 600), configuration: loggedOutConfig)
    let loadedOut = await loadHTMLAndWait(
        loggedOutWebView,
        html: buildMockYTMHTML(loggedIn: false),
        baseURL: URL(string: "https://music.youtube.com/")!
    )
    suite.assert(loadedOut, "Logged-out mock HTML loaded")
    _ = try? await evaluateJS(loggedOutWebView, YTMJavaScript.syncScript)
    _ = try? await evaluateJS(loggedOutWebView, "window.syncYTM(true);")
    _ = await waitUntil(timeout: 2.0) { !loggedOutSpy.payloads.isEmpty }
    suite.assertEqual(loggedOutSpy.payloads.last?["isLoggedIn"] as? Bool, false, "Logged-out DOM reports isLoggedIn == false")

    // Part B: End-to-End through YTMController.shared.webView + userContentController(_:didReceive:)
    suite.section("End-to-End YTMController.shared WKWebView bridge + play()/pause() non-double-toggle")

    let controller = YTMController.shared
    controller.resetPlaylistSelection()
    controller.webView.stopLoading()

    let e2eLoaded = await loadHTMLAndWait(
        controller.webView,
        html: buildMockYTMHTML(loggedIn: true),
        baseURL: URL(string: "https://music.youtube.com/watch?list=PL_SHORT_01")!
    )
    suite.assert(e2eLoaded, "Mock YTM HTML loaded into YTMController.shared.webView")

    _ = try? await evaluateJS(controller.webView, "if (typeof window.syncYTM === 'function') { window.syncYTM(true); }")
    let syncedToController = await waitUntil(timeout: 3.0) {
        controller.currentTitle == "Same Song" &&
        controller.queue.count == 3 &&
        controller.userPlaylists.contains(where: { $0.id == "PL_LONG_87" })
    }
    suite.assert(syncedToController, "YTMController.shared received bridge message and populated metadata/queue/playlists")
    suite.assertEqual(controller.currentArtist, "Band Three", "Controller synced artist")
    suite.assertEqual(controller.isLiked, true, "Controller synced isLiked")
    suite.assertEqual(controller.isDisliked, false, "Controller synced isDisliked")
    suite.assertEqual(controller.repeatMode, 1, "Controller synced repeatMode")
    suite.assertEqual(controller.isShuffle, true, "Controller synced isShuffle")
    suite.assertApprox(controller.duration, 245.0, "Controller synced duration")
    suite.assertApprox(controller.currentTime, 42.5, "Controller synced currentTime")
    suite.assertEqual(controller.isLoggedIn, true, "Controller synced isLoggedIn")

    let sharedDefaults = UserDefaults(suiteName: DefaultsBackup.appGroupSuite)
    suite.assertApprox(sharedDefaults?.double(forKey: "widgetDuration") ?? -1, 245.0, "Widget defaults synced track duration (0 -> 245)")

    // Reset JS call counters, then verify controller.play() and controller.pause() do NOT double-toggle
    _ = try? await evaluateJS(controller.webView, """
    window.__playCalls = 0;
    window.__pauseCalls = 0;
    window.__playBtnClicks = 0;
    window.__mockPaused = true;
    """)

    controller.play()
    await pumpRunLoop(seconds: 0.15)
    let pausedAfterPlay = (try? await evaluateJS(controller.webView, "document.getElementById('mock-video').paused")) as? Bool ?? true
    let playBtnAfterPlay = (try? await evaluateJS(controller.webView, "window.__playBtnClicks")) as? Int ?? -1
    let playCallsAfterPlay = (try? await evaluateJS(controller.webView, "window.__playCalls")) as? Int ?? 0
    suite.assertEqual(pausedAfterPlay, false, "YTMController.play() leaves <video> playing (paused == false)")
    suite.assertEqual(playCallsAfterPlay, 1, "YTMController.play() calls video.play() once")
    suite.assertEqual(playBtnAfterPlay, 0, "YTMController.play() does NOT double-toggle play button")

    // Idempotent play() when already playing must not double-toggle
    controller.play()
    await pumpRunLoop(seconds: 0.1)
    let pausedAfterSecondPlay = (try? await evaluateJS(controller.webView, "document.getElementById('mock-video').paused")) as? Bool ?? true
    let playBtnAfterSecondPlay = (try? await evaluateJS(controller.webView, "window.__playBtnClicks")) as? Int ?? -1
    suite.assertEqual(pausedAfterSecondPlay, false, "Second YTMController.play() keeps <video> playing")
    suite.assertEqual(playBtnAfterSecondPlay, 0, "Second YTMController.play() does NOT toggle play button")

    controller.pause()
    await pumpRunLoop(seconds: 0.15)
    let pausedAfterPause = (try? await evaluateJS(controller.webView, "document.getElementById('mock-video').paused")) as? Bool ?? false
    let mutedAfterPause = (try? await evaluateJS(controller.webView, "document.getElementById('mock-video').muted")) as? Bool ?? false
    let playBtnAfterPause = (try? await evaluateJS(controller.webView, "window.__playBtnClicks")) as? Int ?? -1
    let pauseCallsAfterPause = (try? await evaluateJS(controller.webView, "window.__pauseCalls")) as? Int ?? 0
    suite.assertEqual(pausedAfterPause, true, "YTMController.pause() leaves <video> paused (no toggle back ON)")
    suite.assertEqual(mutedAfterPause, true, "YTMController.pause() mutes <video>")
    suite.assertEqual(pauseCallsAfterPause, 1, "YTMController.pause() calls video.pause() once")
    suite.assertEqual(playBtnAfterPause, 0, "YTMController.pause() does NOT double-toggle play button")

    // Idempotent pause() when already paused must not toggle back ON
    controller.pause()
    await pumpRunLoop(seconds: 0.1)
    let pausedAfterSecondPause = (try? await evaluateJS(controller.webView, "document.getElementById('mock-video').paused")) as? Bool ?? false
    let playBtnAfterSecondPause = (try? await evaluateJS(controller.webView, "window.__playBtnClicks")) as? Int ?? -1
    suite.assertEqual(pausedAfterSecondPause, true, "Second YTMController.pause() keeps <video> paused")
    suite.assertEqual(playBtnAfterSecondPause, 0, "Second YTMController.pause() does NOT toggle play button")

    // Also test YTMController.play()/pause() inline fallback (when window.setPlaybackIntent is absent)
    _ = try? await evaluateJS(controller.webView, """
    window.__savedSetPlaybackIntent = window.setPlaybackIntent;
    delete window.setPlaybackIntent;
    window.__playCalls = 0;
    window.__pauseCalls = 0;
    window.__playBtnClicks = 0;
    window.__mockPaused = true;
    """)

    controller.play()
    await pumpRunLoop(seconds: 0.15)
    let fallbackPausedAfterPlay = (try? await evaluateJS(controller.webView, "document.getElementById('mock-video').paused")) as? Bool ?? true
    let fallbackPlayBtnAfterPlay = (try? await evaluateJS(controller.webView, "window.__playBtnClicks")) as? Int ?? -1
    suite.assertEqual(fallbackPausedAfterPlay, false, "YTMController.play() fallback unpauses <video>")
    suite.assertEqual(fallbackPlayBtnAfterPlay, 0, "YTMController.play() fallback does NOT double-toggle play button")

    controller.pause()
    await pumpRunLoop(seconds: 0.15)
    let fallbackPausedAfterPause = (try? await evaluateJS(controller.webView, "document.getElementById('mock-video').paused")) as? Bool ?? false
    let fallbackPlayBtnAfterPause = (try? await evaluateJS(controller.webView, "window.__playBtnClicks")) as? Int ?? -1
    suite.assertEqual(fallbackPausedAfterPause, true, "YTMController.pause() fallback pauses <video>")
    suite.assertEqual(fallbackPlayBtnAfterPause, 0, "YTMController.pause() fallback does NOT double-toggle play button")

    _ = try? await evaluateJS(controller.webView, """
    window.setPlaybackIntent = window.__savedSetPlaybackIntent;
    delete window.__savedSetPlaybackIntent;
    """)

    // Verify controller.seekTo propagates into live <video>
    controller.seekTo(123.0)
    await pumpRunLoop(seconds: 0.1)
    let videoTimeAfterSeek = (try? await evaluateJS(controller.webView, "document.getElementById('mock-video').currentTime")) as? Double ?? -1
    suite.assertApprox(videoTimeAfterSeek, 123.0, "YTMController.seekTo updates <video>.currentTime")

    // Verify playlist selection race condition protection (< 4.0s transient empty currentListId)
    controller.openPlaylistById("PL_RACE_GUARD")
    controller.webView.stopLoading()
    let loadedTransient = await loadHTMLAndWait(
        controller.webView,
        html: buildMockYTMHTML(loggedIn: true),
        baseURL: URL(string: "https://music.youtube.com/")!
    )
    suite.assert(loadedTransient, "Transient navigation without list= loaded")
    _ = try? await evaluateJS(controller.webView, "if (typeof window.syncYTM === 'function') { window.syncYTM(true); }")
    await pumpRunLoop(seconds: 0.25)
    suite.assertEqual(controller.currentPlaylistId, "PL_RACE_GUARD", "currentPlaylistId is NOT cleared during 4s pending load window")

    // Verify controller like/shuffle/repeat optimistic state survives immediate syncYTM(true) within 1.5s grace window
    _ = try? await evaluateJS(controller.webView, """
    (function() {
      const like = document.getElementById('like-renderer');
      like.setAttribute('like-status', 'INDIFFERENT');
      like.querySelector('#button-shape-like button').setAttribute('aria-pressed', 'false');
      const shuffle = document.querySelector('ytmusic-player-bar .shuffle');
      shuffle.setAttribute('aria-pressed', 'false');
      const rep = document.querySelector('ytmusic-player-bar .repeat');
      rep.setAttribute('aria-pressed', 'false');
      rep.setAttribute('aria-label', 'Repeat off');
    })();
    """)
    controller.isLiked = false
    controller.isShuffle = false
    controller.repeatMode = 0
    controller.likeTrack()
    controller.toggleShuffle()
    controller.toggleRepeat()
    _ = try? await evaluateJS(controller.webView, "if (typeof window.syncYTM === 'function') { window.syncYTM(true); }")
    await pumpRunLoop(seconds: 0.25)
    suite.assertEqual(controller.isLiked, true, "likeTrack state survives immediate syncYTM within grace window")
    suite.assertEqual(controller.isShuffle, true, "toggleShuffle state survives immediate syncYTM within grace window")
    suite.assertEqual(controller.repeatMode, 1, "toggleRepeat state survives immediate syncYTM within grace window")

    // Verify controller controls click real DOM <button> elements via ymacClickControl and syncYTM reads DOM/playerBar state
    _ = try? await evaluateJS(controller.webView, """
    (function() {
      const bar = document.querySelector('ytmusic-player-bar');
      window.__domClicks = { next: 0, prev: 0, shuffle: 0, repeat: 0 };
      bar.shuffleOn = false;
      bar.shuffleEnabled = false;
      bar.repeatMode = 'NONE';

      function ensureInnerBtn(sel) {
        const host = bar.querySelector(sel);
        if (!host) return null;
        let btn = host.querySelector('button');
        if (!btn) {
          btn = document.createElement('button');
          host.appendChild(btn);
        }
        return btn;
      }

      const nextBtn = ensureInnerBtn('.next-button');
      if (nextBtn) nextBtn.addEventListener('click', function() { window.__domClicks.next++; });
      const prevBtn = ensureInnerBtn('.previous-button');
      if (prevBtn) prevBtn.addEventListener('click', function() { window.__domClicks.prev++; });

      const shufHost = bar.querySelector('.shuffle');
      const shufBtn = ensureInnerBtn('.shuffle');
      if (shufBtn) {
        shufBtn.addEventListener('click', function() {
          window.__domClicks.shuffle++;
          bar.shuffleOn = !bar.shuffleOn;
          bar.shuffleEnabled = bar.shuffleOn;
          shufHost.setAttribute('aria-pressed', bar.shuffleOn ? 'true' : 'false');
        });
      }

      const repHost = bar.querySelector('.repeat');
      const repBtn = ensureInnerBtn('.repeat');
      if (repBtn) {
        repBtn.addEventListener('click', function() {
          window.__domClicks.repeat++;
          const cycle = ['NONE', 'ALL', 'ONE'];
          bar.repeatMode = cycle[(cycle.indexOf(bar.repeatMode) + 1) % 3];
        });
      }
    })();
    """)
    controller.isShuffle = false
    controller.repeatMode = 0
    controller.nextTrack()
    controller.previousTrack()
    controller.toggleShuffle()
    controller.toggleRepeat()
    await pumpRunLoop(seconds: 0.2)
    let nextClicks = (try? await evaluateJS(controller.webView, "window.__domClicks.next")) as? Int ?? 0
    let prevClicks = (try? await evaluateJS(controller.webView, "window.__domClicks.prev")) as? Int ?? 0
    let shufOnAfter = (try? await evaluateJS(controller.webView, "Boolean(document.querySelector('ytmusic-player-bar').shuffleOn)")) as? Bool ?? false
    let repModeAfter1 = (try? await evaluateJS(controller.webView, "document.querySelector('ytmusic-player-bar').repeatMode")) as? String ?? ""
    suite.assertEqual(nextClicks, 1, "nextTrack clicks .next-button inner <button>")
    suite.assertEqual(prevClicks, 1, "previousTrack clicks .previous-button inner <button>")
    suite.assertEqual(shufOnAfter, true, "toggleShuffle activates shuffle button via DOM click")
    suite.assertEqual(repModeAfter1, "ALL", "toggleRepeat sets repeatMode = 'ALL' via DOM click")

    controller.toggleShuffle()
    controller.toggleRepeat()
    await pumpRunLoop(seconds: 0.2)
    let shufOffAfter = (try? await evaluateJS(controller.webView, "Boolean(document.querySelector('ytmusic-player-bar').shuffleOn)")) as? Bool ?? true
    let repModeAfter2 = (try? await evaluateJS(controller.webView, "document.querySelector('ytmusic-player-bar').repeatMode")) as? String ?? ""
    let shuffleClicks = (try? await evaluateJS(controller.webView, "window.__domClicks.shuffle")) as? Int ?? 0
    let repeatClicks = (try? await evaluateJS(controller.webView, "window.__domClicks.repeat")) as? Int ?? 0
    suite.assertEqual(shufOffAfter, false, "second toggleShuffle deactivates shuffle button via DOM click")
    suite.assertEqual(repModeAfter2, "ONE", "second toggleRepeat sets repeatMode = 'ONE' via DOM click")
    suite.assertEqual(shuffleClicks, 2, "shuffle inner <button> clicked once per toggleShuffle")
    suite.assertEqual(repeatClicks, 2, "repeat inner <button> clicked once per toggleRepeat")

    // Verify new YouTube Music <ytmusic-miniplayer> / <ytmusic-wiz-player-controls> DOM works end-to-end
    _ = try? await evaluateJS(controller.webView, """
    (function() {
      const oldBar = document.querySelector('ytmusic-player-bar');
      if (oldBar) oldBar.remove();
      window.__wizClicks = { next: 0, prev: 0, like: 0, dislike: 0, shuffle: 0, repeat: 0 };

      const outsideShuffle = document.createElement('button');
      outsideShuffle.setAttribute('aria-label', 'Shuffle');
      outsideShuffle.addEventListener('click', function() { window.__wizClicks.outsideShuffle = true; });
      document.body.appendChild(outsideShuffle);

      const mini = document.createElement('ytmusic-miniplayer');
      mini.innerHTML = `
        <div class="ytMusicMiniPlayerLeftSection">
          <ytmusic-track-info>
            <img class="ytmusicTrackInfoThumbnail" src="https://example.com/thumb.jpg" />
            <div class="ytmusicTrackInfoTitle" title="Wiz Track"><span>Wiz Track</span></div>
            <div class="ytmusicTrackInfoByline"><a>Wiz Artist</a></div>
          </ytmusic-track-info>
        </div>
        <div class="ytMusicMiniPlayerMiddleSection">
          <ytmusic-wiz-player-controls>
            <div class="ytmusicPlayerControlsShuffleButton"><button aria-pressed="true" aria-label="Перемішати"></button></div>
            <div class="ytmusicPlayerControlsPreviousButton"><button aria-label="Назад"></button></div>
            <div class="ytmusicPlayerControlsPlayPauseButton"><button aria-label="Призупинити"></button></div>
            <div class="ytmusicPlayerControlsNextButton"><button aria-label="Далі"></button></div>
            <div class="ytmusicPlayerControlsRepeatButton"><button aria-pressed="true" aria-label="Повторити все"></button></div>
          </ytmusic-wiz-player-controls>
        </div>
        <div class="ytMusicMiniPlayerRightSection">
          <segmented-like-dislike-button-view-model>
            <like-button-view-model><button aria-pressed="true"></button></like-button-view-model>
            <dislike-button-view-model><button aria-pressed="false"></button></dislike-button-view-model>
          </segmented-like-dislike-button-view-model>
        </div>`;
      document.body.appendChild(mini);

      mini.querySelector('.ytmusicPlayerControlsNextButton button').addEventListener('click', () => { window.__wizClicks.next++; });
      mini.querySelector('.ytmusicPlayerControlsPreviousButton button').addEventListener('click', () => { window.__wizClicks.prev++; });
      mini.querySelector('like-button-view-model button').addEventListener('click', function() {
        window.__wizClicks.like++;
        this.setAttribute('aria-pressed', this.getAttribute('aria-pressed') === 'true' ? 'false' : 'true');
      });
      mini.querySelector('dislike-button-view-model button').addEventListener('click', function() {
        window.__wizClicks.dislike++;
        this.setAttribute('aria-pressed', this.getAttribute('aria-pressed') === 'true' ? 'false' : 'true');
      });
      mini.querySelector('.ytmusicPlayerControlsShuffleButton button').addEventListener('click', function() {
        window.__wizClicks.shuffle++;
        this.setAttribute('aria-pressed', this.getAttribute('aria-pressed') === 'true' ? 'false' : 'true');
      });
      const repStates = ['Повторення вимкнено', 'Повторити все', 'Повторити одну композицію'];
      mini.querySelector('.ytmusicPlayerControlsRepeatButton button').addEventListener('click', function() {
        window.__wizClicks.repeat++;
        const nextIdx = (window.__wizClicks.repeat + 1) % 3;
        this.setAttribute('aria-label', repStates[nextIdx]);
        this.setAttribute('aria-pressed', nextIdx > 0 ? 'true' : 'false');
      });

      window.syncYTM(true);
    })();
    """)
    await pumpRunLoop(seconds: 2.6)
    _ = try? await evaluateJS(controller.webView, "window.syncYTM(true)")
    await pumpRunLoop(seconds: 0.2)

    suite.assertEqual(controller.currentTitle, "Wiz Track", "syncYTM reads Wiz track title from ytmusic-miniplayer")
    suite.assertEqual(controller.currentArtist, "Wiz Artist", "syncYTM reads Wiz track artist from ytmusic-miniplayer")
    suite.assertEqual(controller.isLiked, true, "syncYTM reads Wiz like-button-view-model aria-pressed=true")
    suite.assertEqual(controller.isShuffle, true, "syncYTM reads Wiz ytmusicPlayerControlsShuffleButton aria-pressed=true")
    suite.assertEqual(controller.repeatMode, 1, "syncYTM reads Wiz repeat 'Повторити все' as mode 1")

    // Verify controller clicks target Wiz DOM controls inside ytmusic-miniplayer and ignore outside buttons
    controller.nextTrack()
    controller.previousTrack()
    controller.likeTrack()
    controller.dislikeTrack()
    controller.toggleShuffle()
    controller.toggleRepeat()
    await pumpRunLoop(seconds: 0.25)

    let wizNextClicks = (try? await evaluateJS(controller.webView, "window.__wizClicks.next")) as? Int ?? 0
    let wizPrevClicks = (try? await evaluateJS(controller.webView, "window.__wizClicks.prev")) as? Int ?? 0
    let wizLikePressed = (try? await evaluateJS(controller.webView, "document.querySelector('ytmusic-miniplayer like-button-view-model button').getAttribute('aria-pressed')")) as? String ?? ""
    let wizDislikePressed = (try? await evaluateJS(controller.webView, "document.querySelector('ytmusic-miniplayer dislike-button-view-model button').getAttribute('aria-pressed')")) as? String ?? ""
    let wizShufflePressed = (try? await evaluateJS(controller.webView, "document.querySelector('ytmusic-miniplayer .ytmusicPlayerControlsShuffleButton button').getAttribute('aria-pressed')")) as? String ?? ""
    let wizRepeatAria = (try? await evaluateJS(controller.webView, "document.querySelector('ytmusic-miniplayer .ytmusicPlayerControlsRepeatButton button').getAttribute('aria-label')")) as? String ?? ""
    let wizOutsideClicked = (try? await evaluateJS(controller.webView, "Boolean(window.__wizClicks.outsideShuffle)")) as? Bool ?? false
    suite.assertEqual(wizNextClicks, 1, "Wiz miniplayer next button clicked")
    suite.assertEqual(wizPrevClicks, 1, "Wiz miniplayer previous button clicked")
    suite.assertEqual(wizLikePressed, "false", "Wiz miniplayer like button toggled via DOM click")
    suite.assertEqual(wizDislikePressed, "true", "Wiz miniplayer dislike button toggled via DOM click")
    suite.assertEqual(wizShufflePressed, "false", "Wiz miniplayer shuffle button toggled via DOM click")
    suite.assertEqual(wizRepeatAria, "Повторити одну композицію", "Wiz miniplayer repeat button cycled to ONE via DOM click")
    suite.assertEqual(wizOutsideClicked, false, "Wiz miniplayer scoped shuffle click ignores outside button")

    // Verify controller syncs Repeat ONE ('Повторити одну композицію' -> 2) once the 2.5s grace window expires
    controller.repeatMode = 0
    await pumpRunLoop(seconds: 2.6)
    _ = try? await evaluateJS(controller.webView, "window.syncYTM(true)")
    await pumpRunLoop(seconds: 0.2)
    suite.assertEqual(controller.repeatMode, 2, "syncYTM reads Wiz repeat 'Повторити одну композицію' as mode 2")

    // Verify ytmusic-playlist-panel-video-wrapper-renderer AV counterparts (#counterpart-renderer[hidden]) are not duplicated in queue
    _ = try? await evaluateJS(controller.webView, """
    (function() {
      const oldQueue = document.querySelector('ytmusic-player-queue');
      if (oldQueue) oldQueue.remove();
      window.__wrapperClicks = [];
      const queueEl = document.createElement('ytmusic-player-queue');
      queueEl.innerHTML = `
        <ytmusic-playlist-panel-video-wrapper-renderer>
          <div id="primary-renderer">
            <ytmusic-player-queue-item>
              <div class="song-title">Відпусти</div>
              <div class="byline">Океан Ельзи</div>
              <ytmusic-play-button-renderer><button></button></ytmusic-play-button-renderer>
            </ytmusic-player-queue-item>
          </div>
          <div id="counterpart-renderer" hidden="">
            <ytmusic-player-queue-item>
              <div class="song-title">Відпусти</div>
              <div class="byline">Океан Ельзи</div>
              <ytmusic-play-button-renderer><button></button></ytmusic-play-button-renderer>
            </ytmusic-player-queue-item>
          </div>
        </ytmusic-playlist-panel-video-wrapper-renderer>
        <ytmusic-playlist-panel-video-wrapper-renderer>
          <div id="primary-renderer">
            <ytmusic-player-queue-item selected>
              <div class="song-title">Все буде добре</div>
              <div class="byline">Океан Ельзи</div>
              <ytmusic-play-button-renderer><button></button></ytmusic-play-button-renderer>
            </ytmusic-player-queue-item>
          </div>
          <div id="counterpart-renderer" hidden="">
            <ytmusic-player-queue-item selected>
              <div class="song-title">Все буде добре</div>
              <div class="byline">Океан Ельзи</div>
              <ytmusic-play-button-renderer><button></button></ytmusic-play-button-renderer>
            </ytmusic-player-queue-item>
          </div>
        </ytmusic-playlist-panel-video-wrapper-renderer>
        <ytmusic-playlist-panel-video-wrapper-renderer>
          <div id="primary-renderer">
            <ytmusic-player-queue-item>
              <div class="song-title">#Без тебе мене нема</div>
              <div class="byline">Океан Ельзи</div>
              <ytmusic-play-button-renderer><button></button></ytmusic-play-button-renderer>
            </ytmusic-player-queue-item>
          </div>
          <div id="counterpart-renderer" hidden="">
            <ytmusic-player-queue-item>
              <div class="song-title">Океан Ельзи - #БезТебеМенеНема (official video)</div>
              <div class="byline">Океан Ельзи</div>
              <ytmusic-play-button-renderer><button></button></ytmusic-play-button-renderer>
            </ytmusic-player-queue-item>
          </div>
        </ytmusic-playlist-panel-video-wrapper-renderer>`;
      document.body.appendChild(queueEl);
      queueEl.querySelectorAll('ytmusic-player-queue-item').forEach(function(item, rawIdx) {
        const btn = item.querySelector('button');
        const title = item.querySelector('.song-title').textContent;
        btn.addEventListener('click', function() {
          window.__wrapperClicks.push({ rawIdx: rawIdx, title: title });
        });
      });
      window.syncYTM(true);
    })();
    """)
    await pumpRunLoop(seconds: 0.2)

    suite.assertEqual(controller.queue.count, 3, "Queue filters out hidden #counterpart-renderer AV duplicates")
    if controller.queue.count == 3 {
        suite.assertEqual(controller.queue[0].title, "Відпусти", "Deduplicated queue[0] title")
        suite.assertEqual(controller.queue[1].title, "Все буде добре", "Deduplicated queue[1] title")
        suite.assertEqual(controller.queue[2].title, "#Без тебе мене нема", "Deduplicated queue[2] keeps primary item instead of official video counterpart")
        suite.assertEqual(controller.queue[2].originalIndex, 2, "Deduplicated queue[2] has originalIndex 2")
        controller.playQueueItem(at: controller.queue[2].originalIndex)
        await pumpRunLoop(seconds: 0.2)
        let clickedTitle = (try? await evaluateJS(controller.webView, "window.__wrapperClicks[0] ? window.__wrapperClicks[0].title : ''")) as? String ?? ""
        suite.assertEqual(clickedTitle, "#Без тебе мене нема", "playQueueItem clicks the matching primary non-hidden item")
    }

    // Verify selected playlist does NOT drop back to empty when URL loses ?list= (SPA Home/Miniplayer) and resolves via movie_player / header
    controller.userPlaylists = [
        YTMPlaylist(id: "PL_KEEP_1", title: "Океан Ельзи", path: "playlist?list=PL_KEEP_1"),
        YTMPlaylist(id: "PL_KEEP_2", title: "Кровосток", path: "playlist?list=PL_KEEP_2")
    ]
    controller.openPlaylistById("VLPL_KEEP_1")
    suite.assertEqual(controller.currentPlaylistId, "PL_KEEP_1", "openPlaylistById strips VL browse prefix")

    _ = try? await evaluateJS(controller.webView, """
    (function() {
      const mp = document.createElement('div');
      mp.id = 'movie_player';
      mp.getPlaylistId = function() { return 'VLPL_KEEP_1'; };
      document.body.appendChild(mp);
      window.syncYTM(true);
    })();
    """)
    await pumpRunLoop(seconds: 0.2)
    suite.assertEqual(controller.currentPlaylistId, "PL_KEEP_1", "currentPlaylistId resolves from #movie_player.getPlaylistId() with VL stripped when URL has no list=")

    // Simulate SPA clearing both URL and movie_player list id transiently -> currentPlaylistId stays selected (no drop to 'Select Playlist')
    _ = try? await evaluateJS(controller.webView, """
    (function() {
      const mp = document.getElementById('movie_player');
      if (mp) mp.getPlaylistId = function() { return ''; };
      window.syncYTM(true);
    })();
    """)
    await pumpRunLoop(seconds: 0.2)
    suite.assertEqual(controller.currentPlaylistId, "PL_KEEP_1", "currentPlaylistId stays selected instead of dropping to empty when activeBrowserListId becomes empty")

    // Verify playlists filter preserves full /library/playlists list when playing a track on a non-library page
    controller.libraryFilter = .playlists
    controller.userPlaylists = [
        YTMPlaylist(id: "PL_LIB_1", title: "Lib One", path: "playlist?list=PL_LIB_1"),
        YTMPlaylist(id: "PL_LIB_2", title: "Lib Two", path: "playlist?list=PL_LIB_2"),
        YTMPlaylist(id: "PL_LIB_3", title: "Lib Three", path: "playlist?list=PL_LIB_3")
    ]
    _ = try? await evaluateJS(controller.webView, """
    (function() {
      document.querySelectorAll('ytmusic-guide-section-renderer, ytmusic-two-row-item-renderer, ytmusic-responsive-list-item-renderer').forEach(el => el.remove());
      const guide = document.createElement('ytmusic-guide-section-renderer');
      guide.innerHTML = '<ytmusic-guide-entry-renderer><a href="playlist?list=PL_LIB_1">Lib One</a></ytmusic-guide-entry-renderer>';
      document.body.appendChild(guide);
      window.syncYTM(true);
    })();
    """)
    await pumpRunLoop(seconds: 0.2)
    suite.assertEqual(controller.userPlaylists.count, 3, "All-playlists filter keeps full 3-item list when non-library watch page reports fewer pinned entries")

    controller.libraryFilter = .favoritePlaylists
    controller.resetPlaylistSelection()
    controller.webView.stopLoading()
}

#elseif TEST_WIDGET

@MainActor
private struct TestWidgetTimeFormatting: WidgetTimeFormatting {
    let entry: SimpleEntry
}

@MainActor
private func makeTestEntry(
    date: Date = Date(timeIntervalSince1970: 1_700_000_000),
    currentTime: Double,
    duration: Double,
    isPlaying: Bool = true
) -> SimpleEntry {
    SimpleEntry(
        date: date,
        title: "Test Track",
        artist: "Test Artist",
        artworkImage: nil,
        isPlaying: isPlaying,
        currentTime: currentTime,
        duration: duration,
        isShuffle: false,
        repeatMode: 0,
        isLoggedIn: true,
        hasSelectedPlaylist: true,
        language: .english,
        playlists: [],
        isAppRunning: true
    )
}

@MainActor
private func runWidgetTimeFormattingAndTimerMathTests(_ suite: TestSuite) {
    suite.section("WidgetTimeFormatting.formatTime & timerRange math")

    let baseDate = Date(timeIntervalSince1970: 1_700_000_000)
    let formatter = TestWidgetTimeFormatting(entry: makeTestEntry(date: baseDate, currentTime: 0, duration: 200))

    // formatTime edge cases
    suite.assertEqual(formatter.formatTime(0), "0:00", "Widget formatTime(0)")
    suite.assertEqual(formatter.formatTime(-5), "0:00", "Widget formatTime(-5)")
    suite.assertEqual(formatter.formatTime(Double.nan), "0:00", "Widget formatTime(NaN)")
    suite.assertEqual(formatter.formatTime(Double.infinity), "0:00", "Widget formatTime(+Inf)")
    suite.assertEqual(formatter.formatTime(-Double.infinity), "0:00", "Widget formatTime(-Inf)")
    suite.assertEqual(formatter.formatTime(59), "0:59", "Widget formatTime(59)")
    suite.assertEqual(formatter.formatTime(60), "1:00", "Widget formatTime(60)")
    suite.assertEqual(formatter.formatTime(3599), "59:59", "Widget formatTime(3599)")
    suite.assertEqual(formatter.formatTime(3600), "1:00:00", "Widget formatTime(3600)")
    suite.assertEqual(formatter.formatTime(3661), "1:01:01", "Widget formatTime(3661)")

    // timerRange math when currentTime == 0
    if let range0 = TestWidgetTimeFormatting(entry: makeTestEntry(date: baseDate, currentTime: 0, duration: 200)).timerRange {
        suite.assertApprox(range0.upperBound.timeIntervalSince(range0.lowerBound), 200.0, "timerRange span == duration when currentTime == 0")
        suite.assertApprox(range0.lowerBound.timeIntervalSince(baseDate), 0.0, "timerRange startDate == entry.date when currentTime == 0")
    } else {
        suite.assert(false, "timerRange should be non-nil for 0 / 200")
    }

    // timerRange math when currentTime < duration / 2
    if let rangeEarly = TestWidgetTimeFormatting(entry: makeTestEntry(date: baseDate, currentTime: 40, duration: 200)).timerRange {
        suite.assertApprox(rangeEarly.upperBound.timeIntervalSince(rangeEarly.lowerBound), 200.0, "timerRange span == duration when currentTime < duration/2")
        suite.assertApprox(rangeEarly.lowerBound.timeIntervalSince(baseDate), -40.0, "timerRange startDate == entry.date - 40")
        suite.assertApprox(rangeEarly.upperBound.timeIntervalSince(baseDate), 160.0, "timerRange endDate == entry.date + 160")
    } else {
        suite.assert(false, "timerRange should be non-nil for 40 / 200")
    }

    // Regression test: currentTime > duration / 2 (double-subtraction bug check!)
    let lateFormatter = TestWidgetTimeFormatting(entry: makeTestEntry(date: baseDate, currentTime: 150, duration: 200))
    if let rangeLate = lateFormatter.timerRange {
        suite.assertApprox(
            rangeLate.upperBound.timeIntervalSince(rangeLate.lowerBound),
            200.0,
            "timerRange endDate - startDate == entry.duration even when currentTime > duration / 2"
        )
        suite.assertApprox(
            rangeLate.upperBound.timeIntervalSince(baseDate),
            50.0,
            "timerRange endDate stays 50s in the future relative to entry.date"
        )
        suite.assertApprox(
            lateFormatter.trackStartDate.timeIntervalSince(baseDate),
            -150.0,
            "trackStartDate anchors to entry.date - currentTime"
        )
    } else {
        suite.assert(false, "timerRange should be non-nil for 150 / 200")
    }

    // Invalid / boundary inputs
    suite.assert(TestWidgetTimeFormatting(entry: makeTestEntry(date: baseDate, currentTime: 0, duration: 0)).timerRange == nil, "timerRange nil for duration == 0")
    suite.assert(TestWidgetTimeFormatting(entry: makeTestEntry(date: baseDate, currentTime: 0, duration: -10)).timerRange == nil, "timerRange nil for negative duration")
    suite.assert(TestWidgetTimeFormatting(entry: makeTestEntry(date: baseDate, currentTime: 10, duration: Double.nan)).timerRange == nil, "timerRange nil for NaN duration")
    suite.assert(TestWidgetTimeFormatting(entry: makeTestEntry(date: baseDate, currentTime: 10, duration: Double.infinity)).timerRange == nil, "timerRange nil for infinite duration")
    suite.assert(TestWidgetTimeFormatting(entry: makeTestEntry(date: baseDate, currentTime: 200, duration: 200)).timerRange == nil, "timerRange nil when currentTime == duration")
    suite.assert(TestWidgetTimeFormatting(entry: makeTestEntry(date: baseDate, currentTime: 250, duration: 200)).timerRange == nil, "timerRange nil when currentTime > duration")

    let negativeTimeFormatter = TestWidgetTimeFormatting(entry: makeTestEntry(date: baseDate, currentTime: -15, duration: 200))
    suite.assert(negativeTimeFormatter.timerRange == nil, "timerRange nil for negative currentTime")
    suite.assertApprox(negativeTimeFormatter.trackStartDate.timeIntervalSince(baseDate), 0.0, "trackStartDate clamps negative currentTime to 0")

    // WidgetTimeFormatting sanitization & display helpers
    let dirtyEntry = SimpleEntry(
        date: baseDate,
        title: "   ",
        artist: "  ",
        artworkImage: nil,
        isPlaying: false,
        currentTime: 350,
        duration: 200,
        isShuffle: false,
        repeatMode: 99,
        isLoggedIn: true,
        hasSelectedPlaylist: true,
        language: .ukrainian,
        playlists: [
            WidgetPlaylistItem(id: " ", title: "Empty ID"),
            WidgetPlaylistItem(id: "PL_1", title: "   "),
            WidgetPlaylistItem(id: " PL_1 ", title: " First Mix "),
            WidgetPlaylistItem(id: "PL_1", title: "Duplicate Mix"),
            WidgetPlaylistItem(id: "PL_2", title: "Second Mix")
        ],
        isAppRunning: true
    )
    let dirtyFormatter = TestWidgetTimeFormatting(entry: dirtyEntry)
    suite.assertEqual(dirtyFormatter.displayTitle, "Ymac Player", "displayTitle falls back to Ymac Player on blank title")
    suite.assertEqual(dirtyFormatter.displayArtist, LocalizedStrings.paused(.ukrainian), "displayArtist falls back to localized paused label")
    suite.assertApprox(dirtyFormatter.safeDuration, 200.0, "safeDuration returns finite positive duration")
    suite.assertApprox(dirtyFormatter.clampedCurrentTime, 200.0, "clampedCurrentTime clamps overshot currentTime to duration")
    suite.assertApprox(dirtyFormatter.progressValue, 200.0, "progressValue matches clamped time")
    suite.assertApprox(dirtyFormatter.progressTotal, 200.0, "progressTotal matches safeDuration")
    suite.assertEqual(dirtyFormatter.normalizedRepeatMode, 0, "normalizedRepeatMode clamps invalid repeatMode to 0")
    suite.assertEqual(dirtyFormatter.validPlaylists.count, 2, "validPlaylists strips blank/duplicate entries")
    suite.assertEqual(dirtyFormatter.validPlaylists.first?.id, "PL_1", "validPlaylists trims ID")
    suite.assertEqual(dirtyFormatter.validPlaylists.first?.title, "First Mix", "validPlaylists trims title and keeps first duplicate")

    let invalidDurFormatter = TestWidgetTimeFormatting(entry: makeTestEntry(date: baseDate, currentTime: Double.nan, duration: Double.nan, isPlaying: true))
    suite.assertApprox(invalidDurFormatter.safeDuration, 0.0, "safeDuration returns 0 for NaN")
    suite.assertApprox(invalidDurFormatter.clampedCurrentTime, 0.0, "clampedCurrentTime returns 0 for NaN")
    suite.assertApprox(invalidDurFormatter.progressValue, 0.0, "progressValue returns 0 when duration is 0")
    suite.assertApprox(invalidDurFormatter.progressTotal, 1.0, "progressTotal returns 1 fallback when duration is 0")
    suite.assertApprox(invalidDurFormatter.trackStartDate.timeIntervalSince(baseDate), 0.0, "trackStartDate handles NaN safely")
}

@MainActor
private func runWidgetIntentsTests(_ suite: TestSuite) async {
    suite.section("Widget AppIntents optimistic UserDefaults updates")

    guard let defaults = UserDefaults(suiteName: DefaultsBackup.appGroupSuite) else {
        suite.assert(false, "Unable to open App Group UserDefaults suite")
        return
    }

    defaults.set(true, forKey: "widgetIsAppRunning")
    defaults.set(true, forKey: "widgetIsLoggedIn")
    defaults.set(false, forKey: "widgetIsShuffle")
    defaults.set(0, forKey: "widgetRepeatMode")
    defaults.set(false, forKey: "widgetIsPlaying")
    defaults.set([["id": "PL_W1", "title": "Widget Mix", "path": "playlist?list=PL_W1"]], forKey: "widgetPlaylists")
    defaults.synchronize()

    do {
        _ = try await ToggleShuffleIntent().perform()
        suite.assertEqual(defaults.bool(forKey: "widgetIsShuffle"), true, "ToggleShuffleIntent toggles widgetIsShuffle false -> true")
        _ = try await ToggleShuffleIntent().perform()
        suite.assertEqual(defaults.bool(forKey: "widgetIsShuffle"), false, "ToggleShuffleIntent toggles widgetIsShuffle true -> false")

        _ = try await ToggleRepeatIntent().perform()
        suite.assertEqual(defaults.integer(forKey: "widgetRepeatMode"), 1, "ToggleRepeatIntent cycles 0 -> 1")
        _ = try await ToggleRepeatIntent().perform()
        suite.assertEqual(defaults.integer(forKey: "widgetRepeatMode"), 2, "ToggleRepeatIntent cycles 1 -> 2")
        _ = try await ToggleRepeatIntent().perform()
        suite.assertEqual(defaults.integer(forKey: "widgetRepeatMode"), 0, "ToggleRepeatIntent cycles 2 -> 0")

        _ = try await TogglePlayIntent().perform()
        suite.assertEqual(defaults.bool(forKey: "widgetIsPlaying"), true, "TogglePlayIntent toggles widgetIsPlaying false -> true")
        _ = try await TogglePlayIntent().perform()
        suite.assertEqual(defaults.bool(forKey: "widgetIsPlaying"), false, "TogglePlayIntent toggles widgetIsPlaying true -> false")

        _ = try await NextTrackIntent().perform()
        suite.assertEqual(defaults.bool(forKey: "widgetIsPlaying"), true, "NextTrackIntent sets widgetIsPlaying = true")

        defaults.set(false, forKey: "widgetIsPlaying")
        _ = try await PreviousTrackIntent().perform()
        suite.assertEqual(defaults.bool(forKey: "widgetIsPlaying"), true, "PreviousTrackIntent sets widgetIsPlaying = true")

        _ = try await SelectPlaylistIntent(playlistID: "  PL_W1  ").perform()
        suite.assertEqual(defaults.string(forKey: "pendingSelectedPlaylistID"), "PL_W1", "SelectPlaylistIntent stores trimmed playlist ID")
        suite.assertEqual(defaults.bool(forKey: "widgetHasSelectedPlaylist"), true, "SelectPlaylistIntent sets widgetHasSelectedPlaylist")
        suite.assertEqual(defaults.string(forKey: "widgetTitle"), "Widget Mix", "SelectPlaylistIntent updates widgetTitle from widgetPlaylists")

        _ = try await ResetPlaylistIntent().perform()
        suite.assertEqual(defaults.bool(forKey: "widgetHasSelectedPlaylist"), false, "ResetPlaylistIntent clears widgetHasSelectedPlaylist")
        suite.assertEqual(defaults.string(forKey: "widgetTitle"), "Ymac Player", "ResetPlaylistIntent resets widgetTitle")
        suite.assertEqual(defaults.bool(forKey: "widgetIsPlaying"), false, "ResetPlaylistIntent resets widgetIsPlaying")

        // Guard when app is not running
        defaults.set(false, forKey: "widgetIsAppRunning")
        defaults.set(false, forKey: "widgetIsShuffle")
        defaults.set(0, forKey: "widgetRepeatMode")
        defaults.set(false, forKey: "widgetIsPlaying")
        defaults.set(false, forKey: "widgetHasSelectedPlaylist")
        defaults.set("Ymac Player", forKey: "widgetTitle")
        defaults.removeObject(forKey: "pendingSelectedPlaylistID")
        _ = try await ToggleShuffleIntent().perform()
        _ = try await ToggleRepeatIntent().perform()
        _ = try await TogglePlayIntent().perform()
        _ = try await SelectPlaylistIntent(playlistID: "PL_W1").perform()
        suite.assertEqual(defaults.bool(forKey: "widgetIsShuffle"), false, "ToggleShuffleIntent is no-op when app not running")
        suite.assertEqual(defaults.integer(forKey: "widgetRepeatMode"), 0, "ToggleRepeatIntent is no-op when app not running")
        suite.assertEqual(defaults.bool(forKey: "widgetIsPlaying"), false, "TogglePlayIntent is no-op when app not running")
        suite.assertEqual(defaults.bool(forKey: "widgetHasSelectedPlaylist"), false, "SelectPlaylistIntent is no-op when app not running")
        suite.assert(defaults.string(forKey: "pendingSelectedPlaylistID") == nil, "SelectPlaylistIntent does not queue pending ID when app not running")

        defaults.set(true, forKey: "widgetHasSelectedPlaylist")
        defaults.set("Active Track", forKey: "widgetTitle")
        _ = try await ResetPlaylistIntent().perform()
        suite.assertEqual(defaults.bool(forKey: "widgetHasSelectedPlaylist"), true, "ResetPlaylistIntent is no-op when app not running")
        suite.assertEqual(defaults.string(forKey: "widgetTitle"), "Active Track", "ResetPlaylistIntent does not corrupt title when app not running")

        // Out-of-range repeat normalization & logged-out guard
        defaults.set(true, forKey: "widgetIsAppRunning")
        defaults.set(true, forKey: "widgetIsLoggedIn")
        defaults.set(99, forKey: "widgetRepeatMode")
        _ = try await ToggleRepeatIntent().perform()
        suite.assertEqual(defaults.integer(forKey: "widgetRepeatMode"), 1, "ToggleRepeatIntent normalizes out-of-range repeatMode 99 -> 0 -> 1")

        defaults.set(false, forKey: "widgetIsLoggedIn")
        defaults.set(false, forKey: "widgetIsShuffle")
        defaults.set(false, forKey: "widgetIsPlaying")
        _ = try await ToggleShuffleIntent().perform()
        _ = try await TogglePlayIntent().perform()
        _ = try await SelectPlaylistIntent(playlistID: "PL_W1").perform()
        suite.assertEqual(defaults.bool(forKey: "widgetIsShuffle"), false, "ToggleShuffleIntent is no-op when logged out")
        suite.assertEqual(defaults.bool(forKey: "widgetIsPlaying"), false, "TogglePlayIntent is no-op when logged out")
        suite.assert(defaults.string(forKey: "pendingSelectedPlaylistID") == nil, "SelectPlaylistIntent is no-op when logged out")
    } catch {
        suite.assert(false, "AppIntent perform threw unexpected error: \(error)")
    }
}

#endif

// MARK: - Entry Point

@main
struct YmacPlayerTestRunner {
    @MainActor
    static func main() async {
        let backup = DefaultsBackup()
        backup.capture()

        let failureCount = await runSuite(backup: backup)
        if failureCount > 0 {
            Darwin.exit(1)
        } else {
            Darwin.exit(0)
        }
    }

    @MainActor
    private static func runSuite(backup: DefaultsBackup) async -> Int {
        defer {
            backup.restore()
        }

        #if TEST_APP
        NSApplication.shared.setActivationPolicy(.accessory)
        let suite = TestSuite(name: "YmacPlayer App Tests")
        runModelsAndCodableTests(suite)
        runLocalizationCompletenessTests(suite)
        runAppFormatTimeTests(suite)
        await runYTMControllerStateAndDefaultsTests(suite)
        await runWKWebViewJSIntegrationTests(suite)
        return suite.printSummary()
        #elseif TEST_WIDGET
        let suite = TestSuite(name: "YmacPlayer Widget Tests")
        runModelsAndCodableTests(suite)
        runLocalizationCompletenessTests(suite)
        runWidgetTimeFormattingAndTimerMathTests(suite)
        await runWidgetIntentsTests(suite)
        return suite.printSummary()
        #else
        #error("Compile with -DTEST_APP or -DTEST_WIDGET")
        #endif
    }
}
