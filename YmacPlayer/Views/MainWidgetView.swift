import SwiftUI

// MARK: - Main Widget View

/// The primary UI view displayed inside the macOS menu bar popover for Ymac Player.
struct MainWidgetView: View {

    @EnvironmentObject private var controller: YTMController

    @State private var showFullBrowser = false
    @State private var showQueuePopover = false

    var body: some View {
        VStack(spacing: 10) {
            header

            if showFullBrowser {
                HiddenWebView()
                    .frame(height: 380)
                    .cornerRadius(8)
            } else {
                compactPlayer
            }
        }
        .padding(12)
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
                        Text("Back")
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
                        Text("Login")
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
            }
        }
    }

    // MARK: - Compact Player Views

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

            if controller.hasSelectedPlaylist {
                artworkGradient
                playerOverlay
            }
        }
        .frame(width: 260, height: 260)
        .cornerRadius(14)
        .clipped()
    }

    @ViewBuilder
    private var artwork: some View {
        if controller.hasSelectedPlaylist,
           let url = URL(string: controller.artworkUrl),
           !controller.artworkUrl.isEmpty {

            AsyncImage(url: url) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Color.gray.opacity(0.2)
                }
            }
        } else {
            VStack(spacing: 10) {
                Image(systemName: "music.note.house")
                    .font(.system(size: 48))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.gray.opacity(0.12))
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
    }

    @ViewBuilder
    private var trackText: some View {
        VStack(spacing: 2) {
            if !controller.currentTitle.isEmpty,
               controller.currentTitle != "Ymac Player",
               controller.currentTitle != "Ymac",
               controller.currentTitle != "YouTube Music" {

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
                Text(LocalizedStrings.loadingPlaylists(controller.currentLanguage))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
    }

    private var progressControls: some View {
        VStack(spacing: 1) {
            Slider(
                value: Binding(
                    get: { controller.currentTime },
                    set: { controller.currentTime = $0 }
                ),
                in: 0...max(controller.duration, 1),
                onEditingChanged: { editing in
                    controller.isEditingSlider = editing
                    if !editing {
                        controller.seekTo(controller.currentTime)
                    }
                }
            )
            .tint(.red)

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

            Spacer()
        }
        .disabled(!controller.hasSelectedPlaylist)
        .opacity(controller.hasSelectedPlaylist ? 1.0 : 0.4)
    }

    private func formatTime(_ timeInSeconds: Double) -> String {
        guard !timeInSeconds.isNaN, !timeInSeconds.isInfinite else { return "0:00" }
        let totalSeconds = Int(timeInSeconds)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
