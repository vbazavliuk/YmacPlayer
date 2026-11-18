import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Playlist Data Model for Widget

/// Represents a playlist item stored and rendered within the widget context.
struct WidgetPlaylistItem: Identifiable, Hashable {
    let id: String
    let title: String
}

// MARK: - Widget Timeline Entry

/// The timeline entry model containing playback state and user preferences for Ymac Player widgets.
struct SimpleEntry: TimelineEntry {
    let date: Date
    let title: String
    let artist: String
    let artworkImage: NSImage?
    let isPlaying: Bool
    let currentTime: Double
    let duration: Double
    let isShuffle: Bool
    let repeatMode: Int
    let isLoggedIn: Bool
    let hasSelectedPlaylist: Bool
    let language: AppLanguage
    let playlists: [WidgetPlaylistItem]
    let isAppRunning: Bool
}

// MARK: - Shared Widget Time Formatting

/// Shared timer/progress helpers used by both the small and medium widget layouts,
/// avoiding duplicated logic across the two views.
protocol WidgetTimeFormatting {
    var entry: SimpleEntry { get }
}

extension WidgetTimeFormatting {
    var trackStartDate: Date {
        let safeCurrentTime = entry.currentTime.isFinite ? max(0, entry.currentTime) : 0
        return entry.date.addingTimeInterval(-safeCurrentTime)
    }

    /// A valid date range for `ProgressView(timerInterval:)`.
    /// Returns nil when the range would be invalid (non-finite, zero/negative duration, or elapsed >= duration).
    var timerRange: ClosedRange<Date>? {
        guard entry.duration.isFinite,
              entry.currentTime.isFinite,
              entry.duration > 0,
              entry.currentTime >= 0,
              entry.currentTime < entry.duration
        else { return nil }
        let startDate = entry.date.addingTimeInterval(-entry.currentTime)
        let endDate = startDate.addingTimeInterval(entry.duration)
        guard endDate > startDate else { return nil }
        return startDate...endDate
    }

    var safeDuration: Double {
        guard entry.duration.isFinite, entry.duration > 0 else { return 0 }
        return entry.duration
    }

    var clampedCurrentTime: Double {
        guard entry.currentTime.isFinite, entry.currentTime > 0 else { return 0 }
        return safeDuration > 0 ? min(entry.currentTime, safeDuration) : entry.currentTime
    }

    var progressValue: Double {
        guard safeDuration > 0 else { return 0 }
        return min(clampedCurrentTime, safeDuration)
    }

    var progressTotal: Double {
        safeDuration > 0 ? safeDuration : 1
    }

    var displayTitle: String {
        let trimmed = entry.title.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Ymac Player" : trimmed
    }

    var displayArtist: String {
        let trimmed = entry.artist.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            return trimmed
        } else if entry.isPlaying {
            return LocalizedStrings.playing(entry.language)
        } else {
            return LocalizedStrings.paused(entry.language)
        }
    }

    var normalizedRepeatMode: Int {
        (0...2).contains(entry.repeatMode) ? entry.repeatMode : 0
    }

    var validPlaylists: [WidgetPlaylistItem] {
        var seenIDs = Set<String>()
        return entry.playlists.compactMap { item in
            let cleanID = item.id.trimmingCharacters(in: .whitespacesAndNewlines)
            let cleanTitle = item.title.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !cleanID.isEmpty, !cleanTitle.isEmpty, seenIDs.insert(cleanID).inserted else {
                return nil
            }
            return WidgetPlaylistItem(id: cleanID, title: cleanTitle)
        }
    }

    func formatTime(_ seconds: Double) -> String {
        guard seconds.isFinite, seconds >= 0, seconds < Double(Int.max) else { return "0:00" }
        let total = Int(seconds)
        let hours = total / 3600
        let mins = (total % 3600) / 60
        let secs = total % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, mins, secs)
        } else {
            return String(format: "%d:%02d", mins, secs)
        }
    }

    @ViewBuilder
    func progressBarView() -> some View {
        if entry.isPlaying, let range = timerRange {
            ProgressView(timerInterval: range, countsDown: false) {
                EmptyView()
            } currentValueLabel: {
                EmptyView()
            }
            .tint(.red)
        } else {
            ProgressView(
                value: progressValue,
                total: progressTotal
            )
            .tint(entry.isPlaying ? .red : .gray)
        }
    }

    @ViewBuilder
    func timeLabelsView() -> some View {
        HStack {
            if entry.isPlaying, timerRange != nil {
                Text(trackStartDate, style: .timer)
            } else {
                Text(formatTime(clampedCurrentTime))
            }

            Spacer()

            Text(formatTime(safeDuration))
        }
    }

    @ViewBuilder
    func widgetBackgroundView(topOpacity: Double) -> some View {
        ZStack {
            if entry.isAppRunning && entry.hasSelectedPlaylist, let nsImage = entry.artworkImage {
                Image(nsImage: nsImage)
                    .resizable()
                    .scaledToFill()
            } else {
                Color.black
            }

            LinearGradient(
                colors: [.black.opacity(topOpacity), .black.opacity(0.88)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
}

// MARK: - Timeline Provider

/// Provides snapshot and timeline entries sourced from shared App Group UserDefaults and storage.
struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(
            date: Date(),
            title: "Ymac Player",
            artist: "Playing",
            artworkImage: NSImage(named: "WidgetBackground") ?? NSImage(systemSymbolName: "music.note", accessibilityDescription: nil),
            isPlaying: true,
            currentTime: 30,
            duration: 200,
            isShuffle: false,
            repeatMode: 0,
            isLoggedIn: true,
            hasSelectedPlaylist: true,
            language: .english,
            playlists: [
                WidgetPlaylistItem(id: "1", title: "My Mix"),
                WidgetPlaylistItem(id: "2", title: "Favorites"),
                WidgetPlaylistItem(id: "3", title: "Chill Hits"),
                WidgetPlaylistItem(id: "4", title: "Workout")
            ],
            isAppRunning: true
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        completion(getEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
        let entry = getEntry()
        let nextRefresh = Date().addingTimeInterval(15 * 60)
        let timeline = Timeline(entries: [entry], policy: .after(nextRefresh))
        completion(timeline)
    }

    private func getEntry() -> SimpleEntry {
        guard let defaults = UserDefaults(suiteName: "9R2Z2PT297.group.com.ymacplayer") else {
            return SimpleEntry(
                date: Date(),
                title: "Ymac Player",
                artist: "",
                artworkImage: nil,
                isPlaying: false,
                currentTime: 0,
                duration: 0,
                isShuffle: false,
                repeatMode: 0,
                isLoggedIn: true,
                hasSelectedPlaylist: false,
                language: .english,
                playlists: [],
                isAppRunning: false
            )
        }

        let rawTitleCheck = defaults.string(forKey: "widgetTitle")?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let isAppRunning = defaults.bool(forKey: "widgetIsAppRunning") || (!rawTitleCheck.isEmpty && rawTitleCheck != "Ymac Player")

        var artworkImage: NSImage? = nil
        if isAppRunning, let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "9R2Z2PT297.group.com.ymacplayer"
        ) {
            let fileURL = containerURL.appendingPathComponent("artwork.png")
            if let image = NSImage(contentsOf: fileURL) {
                artworkImage = image
            }
        }

        let rawTitle = defaults.string(forKey: "widgetTitle") ?? "Ymac Player"
        let trimmedTitle = rawTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let title = (trimmedTitle.isEmpty || trimmedTitle == "YouTube Music" || trimmedTitle == "U-Music" || !isAppRunning)
            ? "Ymac Player"
            : trimmedTitle

        let artist = isAppRunning ? (defaults.string(forKey: "widgetArtist") ?? "") : ""
        let isPlaying = isAppRunning ? defaults.bool(forKey: "widgetIsPlaying") : false
        let rawCurrentTime = isAppRunning ? defaults.double(forKey: "widgetCurrentTime") : 0.0
        let rawDuration = isAppRunning ? defaults.double(forKey: "widgetDuration") : 0.0
        let duration = (rawDuration.isFinite && rawDuration >= 0) ? rawDuration : 0.0
        let currentTime: Double = {
            guard rawCurrentTime.isFinite, rawCurrentTime >= 0 else { return 0.0 }
            return duration > 0 ? min(rawCurrentTime, duration) : rawCurrentTime
        }()
        let isShuffle = isAppRunning ? defaults.bool(forKey: "widgetIsShuffle") : false
        let rawRepeatMode = isAppRunning ? defaults.integer(forKey: "widgetRepeatMode") : 0
        let repeatMode = (0...2).contains(rawRepeatMode) ? rawRepeatMode : 0
        let isLoggedIn = defaults.object(forKey: "widgetIsLoggedIn") != nil ? defaults.bool(forKey: "widgetIsLoggedIn") : true

        let storedHasSelectedPlaylist = defaults.bool(forKey: "widgetHasSelectedPlaylist")
        let hasActiveTrack = isAppRunning && !title.isEmpty && title != "Ymac Player" && title != "Ymac"
        let effectiveHasPlaylist = isAppRunning && (storedHasSelectedPlaylist || hasActiveTrack)

        let langRaw = defaults.string(forKey: "widgetLanguage") ?? "en"
        let language = AppLanguage(rawValue: langRaw) ?? .english

        var playlistsArray: [WidgetPlaylistItem] = []
        if isAppRunning, let rawList = defaults.array(forKey: "widgetPlaylists") as? [[String: String]] {
            var seenIDs = Set<String>()
            playlistsArray = rawList.compactMap { dict in
                guard
                    let id = dict["id"]?.trimmingCharacters(in: .whitespacesAndNewlines),
                    let t = dict["title"]?.trimmingCharacters(in: .whitespacesAndNewlines),
                    !id.isEmpty,
                    !t.isEmpty,
                    seenIDs.insert(id).inserted
                else { return nil }
                return WidgetPlaylistItem(id: id, title: t)
            }
        }

        return SimpleEntry(
            date: Date(),
            title: title,
            artist: artist,
            artworkImage: artworkImage,
            isPlaying: isPlaying,
            currentTime: currentTime,
            duration: duration,
            isShuffle: isShuffle,
            repeatMode: repeatMode,
            isLoggedIn: isLoggedIn,
            hasSelectedPlaylist: effectiveHasPlaylist,
            language: language,
            playlists: playlistsArray,
            isAppRunning: isAppRunning
        )
    }
}

// MARK: - Root Widget View

/// Renders either the small or medium widget layout based on the active widget family.
struct YmacPlayerWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: Provider.Entry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        default:
            MediumWidgetView(entry: entry)
        }
    }
}

// MARK: - Small Widget View (.systemSmall)

struct SmallWidgetView: View, WidgetTimeFormatting {
    let entry: SimpleEntry

    private var appNotRunningView: some View {
        VStack(spacing: 8) {
            Spacer(minLength: 0)

            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.red.opacity(0.25), Color.orange.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)

                Image(systemName: "music.note")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.red, Color.orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            VStack(spacing: 2) {
                Text("Ymac Player")
                    .font(.system(size: 11.5, weight: .bold))
                    .foregroundColor(.white)

                Text(LocalizedStrings.appNotRunning(entry.language))
                    .font(.system(size: 9))
                    .foregroundColor(.white.opacity(0.65))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }

            Spacer(minLength: 0)

            Button(intent: LaunchAppIntent()) {
                HStack(spacing: 4) {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 11, weight: .bold))
                    Text(LocalizedStrings.launchPlayer(entry.language))
                        .font(.system(size: 10, weight: .semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 5)
                .padding(.horizontal, 6)
                .background(
                    LinearGradient(
                        colors: [Color.red, Color.red.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(6)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(2)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            if !entry.isAppRunning {
                appNotRunningView
            } else if !entry.isLoggedIn {
                VStack(alignment: .leading, spacing: 2) {
                    Text(LocalizedStrings.pleaseSignIn(entry.language))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.red)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                }
                .padding(4)
                Spacer()

            } else if !entry.hasSelectedPlaylist {
                // Playlist selection mode
                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text("Ymac Player")
                            .font(.system(size: 10.5, weight: .bold))
                            .foregroundColor(.white.opacity(0.9))
                        Spacer(minLength: 0)
                        Image(systemName: "music.note.list")
                            .font(.system(size: 9.5))
                            .foregroundColor(.yellow)
                    }

                    if validPlaylists.isEmpty {
                        Spacer()
                        Text(LocalizedStrings.loadingPlaylists(entry.language))
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                        Spacer()
                    } else {
                        VStack(spacing: 2.5) {
                            ForEach(validPlaylists.prefix(4), id: \.id) { playlist in
                                Button(intent: SelectPlaylistIntent(playlistID: playlist.id)) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "play.circle.fill")
                                            .font(.system(size: 9.5))
                                            .foregroundColor(.red)
                                        Text(playlist.title)
                                            .font(.system(size: 10.5, weight: .semibold))
                                            .foregroundColor(.white)
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.82)
                                        Spacer(minLength: 0)
                                    }
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(Color.white.opacity(0.14))
                                    .cornerRadius(5)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

            } else {
                // Playback view mode
                VStack(alignment: .leading, spacing: 1) {
                    HStack(alignment: .top, spacing: 2) {
                        VStack(alignment: .leading, spacing: 1) {
                            Text(displayTitle)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                                .lineLimit(1)

                            Text(displayArtist)
                                .font(.system(size: 9))
                                .foregroundColor(.white.opacity(0.8))
                                .lineLimit(1)
                        }

                        Spacer(minLength: 0)

                        // Playlist reset / selection button
                        Button(intent: ResetPlaylistIntent()) {
                            Image(systemName: "music.note.list")
                                .font(.system(size: 9.5, weight: .bold))
                                .foregroundColor(.white.opacity(0.85))
                                .frame(width: 22, height: 22)
                                .background(Color.black.opacity(0.45))
                                .clipShape(Circle())
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 1)

                Spacer(minLength: 0)

                // Progress bar
                progressBarView()

                // Playback timer
                timeLabelsView()
                    .font(.system(size: 8, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.85))
                    .padding(.horizontal, 2)

                // Playback control buttons
                HStack(spacing: 0) {
                    Spacer()
                    Button(intent: ToggleShuffleIntent()) {
                        Image(systemName: "shuffle")
                            .font(.system(size: 9.5, weight: .bold))
                            .foregroundColor(entry.isShuffle ? .blue : .white.opacity(0.5))
                            .frame(width: 20, height: 20)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    Spacer()
                    Button(intent: PreviousTrackIntent()) {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 9.5))
                            .foregroundColor(.white)
                            .frame(width: 20, height: 20)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    Spacer()
                    Button(intent: TogglePlayIntent()) {
                        Image(systemName: entry.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 19))
                            .foregroundColor(.white)
                            .frame(width: 26, height: 22)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    Spacer()
                    Button(intent: NextTrackIntent()) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 9.5))
                            .foregroundColor(.white)
                            .frame(width: 20, height: 20)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    Spacer()
                    Button(intent: ToggleRepeatIntent()) {
                        Image(systemName: normalizedRepeatMode == 2 ? "repeat.1" : "repeat")
                            .font(.system(size: 9.5, weight: .bold))
                            .foregroundColor(normalizedRepeatMode > 0 ? .blue : .white.opacity(0.5))
                            .frame(width: 20, height: 20)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    Spacer()
                }
            }
        }
        .padding(6)
        .containerBackground(for: .widget) {
            widgetBackgroundView(topOpacity: 0.35)
        }
    }
}

// MARK: - Medium Widget View (.systemMedium)

struct MediumWidgetView: View, WidgetTimeFormatting {
    let entry: SimpleEntry

    private var appNotRunningView: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.red.opacity(0.25), Color.orange.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)

                Image(systemName: "music.note")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.red, Color.orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            VStack(alignment: .leading, spacing: 6) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Ymac Player")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)

                    Text(LocalizedStrings.appNotRunning(entry.language))
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.65))
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                }

                Button(intent: LaunchAppIntent()) {
                    HStack(spacing: 5) {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 13, weight: .bold))
                        Text(LocalizedStrings.launchPlayer(entry.language))
                            .font(.system(size: 11.5, weight: .semibold))
                            .lineLimit(1)
                    }
                    .foregroundColor(.white)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .background(
                        LinearGradient(
                            colors: [Color.red, Color.red.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(7)
                }
                .buttonStyle(.plain)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 8)
    }

    var body: some View {
        VStack(spacing: 6) {
            if !entry.isAppRunning {
                appNotRunningView
            } else if !entry.isLoggedIn {
                HStack {
                    Text(LocalizedStrings.pleaseSignIn(entry.language))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.red)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                    Spacer()
                }
                Spacer()

            } else if !entry.hasSelectedPlaylist {
                // Playlist selection mode
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(LocalizedStrings.selectPlaylist(entry.language))
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                        Spacer(minLength: 0)
                        Image(systemName: "music.note.list")
                            .foregroundColor(.yellow)
                    }

                    if validPlaylists.isEmpty {
                        Spacer()
                        Text(LocalizedStrings.loadingPlaylists(entry.language))
                            .font(.system(size: 11))
                            .foregroundColor(.gray)
                        Spacer()
                    } else {
                        VStack(spacing: 3) {
                            ForEach(validPlaylists.prefix(4), id: \.id) { playlist in
                                Button(intent: SelectPlaylistIntent(playlistID: playlist.id)) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "play.circle.fill")
                                            .font(.system(size: 11))
                                            .foregroundColor(.red)
                                        Text(playlist.title)
                                            .font(.system(size: 10, weight: .medium))
                                            .foregroundColor(.white)
                                            .lineLimit(1)
                                        Spacer(minLength: 0)
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.white.opacity(0.12))
                                    .cornerRadius(6)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

            } else {
                // Playback view mode
                HStack(alignment: .top, spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            if entry.isPlaying {
                                Image(systemName: "waveform")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.red)
                            }
                            Text(displayTitle)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .lineLimit(1)
                        }

                        Text(displayArtist)
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.85))
                            .lineLimit(1)
                    }

                    Spacer(minLength: 0)

                    // Reset playlist selection button
                    Button(intent: ResetPlaylistIntent()) {
                        Image(systemName: "music.note.list")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white.opacity(0.85))
                            .frame(width: 26, height: 26)
                            .background(Color.white.opacity(0.18))
                            .clipShape(Circle())
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }

                Spacer(minLength: 0)

                VStack(spacing: 2) {
                    progressBarView()

                    timeLabelsView()
                        .font(.system(size: 9, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.9))
                }

                HStack(spacing: 20) {
                    Spacer()

                    Button(intent: ToggleShuffleIntent()) {
                        Image(systemName: "shuffle")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(entry.isShuffle ? .blue : .white.opacity(0.5))
                            .frame(width: 32, height: 32)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    Button(intent: PreviousTrackIntent()) {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 15))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    Button(intent: TogglePlayIntent()) {
                        Image(systemName: entry.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 34)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    Button(intent: NextTrackIntent()) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 15))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    Button(intent: ToggleRepeatIntent()) {
                        Image(systemName: normalizedRepeatMode == 2 ? "repeat.1" : "repeat")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(normalizedRepeatMode > 0 ? .blue : .white.opacity(0.5))
                            .frame(width: 32, height: 32)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    Spacer()
                }
                .padding(.top, 1)
            }
        }
        .padding(12)
        .containerBackground(for: .widget) {
            widgetBackgroundView(topOpacity: 0.4)
        }
    }
}

// MARK: - Widget Configuration

/// The primary widget declaration for Ymac Player.
struct YmacPlayerWidget: Widget {
    let kind: String = "YmacPlayerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            YmacPlayerWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Ymac Player")
        .description("Control and monitor Ymac Player playback directly from macOS Notification Center or Desktop.")
        .supportedFamilies([.systemMedium, .systemSmall])
    }
}
