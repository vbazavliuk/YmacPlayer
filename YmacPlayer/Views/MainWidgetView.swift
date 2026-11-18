import SwiftUI
import AppKit

struct MainWidgetView: View {

    @EnvironmentObject private var controller: YTMController

    @State private var showFullBrowser = false
    @State private var showQueuePopover = false

    private var safeDuration: Double {
        guard !controller.duration.isNaN, !controller.duration.isInfinite, controller.duration > 0 else {
            return 1.0
        }
        return controller.duration
    }

    private var safeCurrentTime: Double {
        guard !controller.currentTime.isNaN, !controller.currentTime.isInfinite, controller.currentTime >= 0 else {
            return 0.0
        }
        return min(controller.currentTime, safeDuration)
    }

    var body: some View {
        VStack(spacing: 10) {
            header

            if showFullBrowser {
                HiddenWebView()
                    .frame(minWidth: 276, minHeight: 380, maxHeight: 380)
                    .cornerRadius(8)
            } else {
                compactPlayer
            }
        }
        .padding(12)
        .onChange(of: controller.hasActiveTrack) { _, hasActive in
            if !hasActive {
                showQueuePopover = false
                controller.isEditingSlider = false
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSPopover.didCloseNotification)) { _ in
            if showFullBrowser {
                showFullBrowser = false
                let webView = YTMController.shared.webView
                webView.window?.makeFirstResponder(nil)
                webView.translatesAutoresizingMaskIntoConstraints = true
                webView.autoresizingMask = [.width, .height]
                YTMController.shared.attachToBackgroundWindow()
            }
        }
    }

    // MARK: - Header View

    private var header: some View {
        HStack(spacing: 6) {
            if showFullBrowser {
                Button {
                    showFullBrowser = false
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 11, weight: .bold))
                        Text(LocalizedStrings.backButton(controller.currentLanguage))
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.blue)
                    .cornerRadius(6)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help(LocalizedStrings.toggleViewHelp(controller.currentLanguage, showFull: showFullBrowser))

                Spacer()

            } else if !controller.isLoggedIn {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Ymac Player")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)

                    Text(LocalizedStrings.pleaseSignIn(controller.currentLanguage))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.red)
                }

                Spacer()

                Button {
                    showFullBrowser = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "person.crop.circle.badge.plus")
                        Text(LocalizedStrings.loginButton(controller.currentLanguage))
                    }
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.red)
                    .cornerRadius(6)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help(LocalizedStrings.toggleViewHelp(controller.currentLanguage, showFull: false))

            } else {
                Text("Ymac Player")
                    .font(.system(size: 13, weight: .bold))

                Spacer()

                Picker("", selection: Binding(
                    get: { controller.currentPlaylistId },
                    set: { newID in
                        if newID.isEmpty {
                            controller.resetPlaylistSelection()
                        } else {
                            controller.openPlaylistById(newID)
                        }
                    }
                )) {
                    Text(
                        controller.userPlaylists.isEmpty
                            ? LocalizedStrings.loadingPlaylists(controller.currentLanguage)
                            : LocalizedStrings.selectPlaylist(controller.currentLanguage)
                    )
                    .tag("")

                    if !controller.currentPlaylistId.isEmpty && !controller.userPlaylists.contains(where: { $0.id == controller.currentPlaylistId }) {
                        Text(controller.currentTitle)
                            .tag(controller.currentPlaylistId)
                    }

                    ForEach(controller.userPlaylists) { playlist in
                        Text(playlist.title)
                            .tag(playlist.id)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .frame(maxWidth: 150)

                Button {
                    showFullBrowser.toggle()
                } label: {
                    Image(systemName: "globe")
                        .font(.system(size: 13))
                        .frame(width: 28, height: 28)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help(LocalizedStrings.toggleViewHelp(controller.currentLanguage, showFull: showFullBrowser))
            }
        }
    }

    // MARK: - Compact Player

    private var compactPlayer: some View {
        VStack(spacing: 10) {
            artworkPlayer
            Divider()
            reactionControls
        }
    }

    private var artworkPlayer: some View {
        ZStack(alignment: .bottom) {
            artwork
            artworkGradient
            playerOverlay
        }
        .frame(width: 260, height: 260)
        .cornerRadius(14)
        .clipped()
    }

    @ViewBuilder
    private var artwork: some View {
        if controller.hasActiveTrack,
           let url = URL(string: controller.artworkUrl),
           !controller.artworkUrl.isEmpty {
            AsyncImage(url: url) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Color.black.opacity(0.65)
                }
            }
            .frame(width: 260, height: 260)
            .clipped()
        } else {
            VStack(spacing: 10) {
                Image(systemName: "music.note.house")
                    .font(.system(size: 48))
                    .foregroundColor(.white.opacity(0.65))
                    .padding(.bottom, 96)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                LinearGradient(
                    colors: [Color.black.opacity(0.45), Color.black.opacity(0.82)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
    }

    private var artworkGradient: some View {
        VStack {
            Spacer()
            Rectangle()
                .fill(.ultraThinMaterial)
                .mask(
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.85), .black],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 160)
        }
    }

    private var playerOverlay: some View {
        VStack(spacing: 8) {
            trackText
            progressControls
            playbackControls
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 10)
        .frame(width: 260)
    }

    @ViewBuilder
    private var trackText: some View {
        VStack(spacing: 2) {
            if controller.hasActiveTrack {
                Text(controller.currentTitle)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.9), radius: 2)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                if !controller.currentArtist.isEmpty {
                    Text(controller.currentArtist)
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.86))
                        .shadow(color: .black.opacity(0.9), radius: 2)
                        .lineLimit(1)
                }
            } else {
                Text(
                    controller.userPlaylists.isEmpty
                        ? LocalizedStrings.loadingPlaylists(controller.currentLanguage)
                        : LocalizedStrings.selectPlaylistPrompt(controller.currentLanguage)
                )
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white.opacity(0.85))
                .shadow(color: .black.opacity(0.9), radius: 2)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            }
        }
    }

    private var progressControls: some View {
        VStack(spacing: 1) {
            Slider(
                value: Binding(
                    get: { safeCurrentTime },
                    set: { newValue in
                        guard controller.hasActiveTrack else { return }
                        controller.currentTime = newValue
                    }
                ),
                in: 0...safeDuration,
                onEditingChanged: { editing in
                    guard controller.hasActiveTrack else {
                        controller.isEditingSlider = false
                        return
                    }
                    controller.isEditingSlider = editing
                    if !editing {
                        controller.seekTo(controller.currentTime)
                    }
                }
            )
            .tint(.red)
            .disabled(!controller.hasActiveTrack)

            HStack {
                Text(formatTime(controller.currentTime))
                Spacer()
                Text(formatTime(controller.duration))
            }
            .font(.system(size: 10, weight: .semibold, design: .monospaced))
            .foregroundColor(.white.opacity(0.9))
        }
    }

    private var playbackControls: some View {
        ZStack {
            HStack(spacing: 20) {
                Button {
                    controller.previousTrack()
                } label: {
                    Image(systemName: "backward.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(!controller.hasActiveTrack)
                .opacity(controller.hasActiveTrack ? 1.0 : 0.45)

                Button {
                    controller.togglePlay()
                } label: {
                    Image(systemName: controller.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                        .frame(width: 48, height: 48)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(!controller.hasActiveTrack && controller.userPlaylists.isEmpty)
                .opacity((controller.hasActiveTrack || !controller.userPlaylists.isEmpty) ? 1.0 : 0.45)

                Button {
                    controller.nextTrack()
                } label: {
                    Image(systemName: "forward.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(!controller.hasActiveTrack)
                .opacity(controller.hasActiveTrack ? 1.0 : 0.45)
            }

            HStack {
                Spacer()

                Button {
                    showQueuePopover.toggle()
                } label: {
                    Image(systemName: "list.bullet")
                        .font(.title3)
                        .foregroundColor(showQueuePopover ? .blue : .white)
                        .frame(width: 32, height: 36)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(!controller.hasActiveTrack)
                .opacity(controller.hasActiveTrack ? 1.0 : 0.45)
                .help(LocalizedStrings.queueHelp(controller.currentLanguage))
                .popover(isPresented: $showQueuePopover, arrowEdge: .top) {
                    QueuePopoverView(isPresented: $showQueuePopover)
                        .environmentObject(controller)
                }
            }
        }
    }

    private var reactionControls: some View {
        HStack {
            Spacer()

            Button {
                controller.likeTrack()
            } label: {
                Image(systemName: controller.isLiked ? "hand.thumbsup.fill" : "hand.thumbsup")
                    .font(.title2)
                    .foregroundColor(controller.isLiked ? .blue : .primary)
                    .frame(width: 48, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help(LocalizedStrings.likeHelp(controller.currentLanguage))

            Spacer()

            Button {
                controller.toggleShuffle()
            } label: {
                Image(systemName: "shuffle")
                    .font(.title2)
                    .foregroundColor(controller.isShuffle ? .blue : .primary)
                    .frame(width: 48, height: 44)
                    .background(controller.isShuffle ? Color.blue.opacity(0.18) : Color.clear)
                    .clipShape(Circle())
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .help(LocalizedStrings.shuffleHelp(controller.currentLanguage))

            Spacer()

            Button {
                controller.toggleRepeat()
            } label: {
                Image(systemName: controller.repeatMode == 2 ? "repeat.1" : "repeat")
                    .font(.title2)
                    .foregroundColor(controller.repeatMode > 0 ? .blue : .primary)
                    .frame(width: 48, height: 44)
                    .background(controller.repeatMode > 0 ? Color.blue.opacity(0.18) : Color.clear)
                    .clipShape(Circle())
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .help(LocalizedStrings.repeatHelp(controller.currentLanguage, mode: controller.repeatMode))

            Spacer()

            Button {
                controller.dislikeTrack()
            } label: {
                Image(systemName: controller.isDisliked ? "hand.thumbsdown.fill" : "hand.thumbsdown")
                    .font(.title2)
                    .foregroundColor(controller.isDisliked ? .red : .primary)
                    .frame(width: 48, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help(LocalizedStrings.dislikeHelp(controller.currentLanguage))

            Spacer()
        }
        .disabled(!controller.hasActiveTrack)
        .opacity(controller.hasActiveTrack ? 1.0 : 0.4)
    }
}

// MARK: - Safe Time Formatter

public func formatTime(_ timeInSeconds: Double) -> String {
    guard !timeInSeconds.isNaN, !timeInSeconds.isInfinite, timeInSeconds >= 0 else { return "0:00" }
    let totalSeconds = Int(timeInSeconds)
    let hours = totalSeconds / 3600
    let minutes = (totalSeconds % 3600) / 60
    let seconds = totalSeconds % 60

    if hours > 0 {
        return String(format: "%d:%02d:%02d", hours, minutes, seconds)
    } else {
        return String(format: "%d:%02d", minutes, seconds)
    }
}
