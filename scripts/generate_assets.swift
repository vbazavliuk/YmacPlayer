import SwiftUI
import AppKit

// MARK: - Helper to save View as Retina PNG

@MainActor
func saveView<V: View>(_ view: V, size: CGSize, to path: String) {
    let hostingView = NSHostingView(rootView: view.frame(width: size.width, height: size.height))
    hostingView.frame = CGRect(origin: .zero, size: size)

    let renderer = ImageRenderer(content: view.frame(width: size.width, height: size.height))
    renderer.scale = 2.0 // 2x Retina

    guard let nsImage = renderer.nsImage,
          let tiffData = nsImage.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiffData),
          let pngData = bitmap.representation(using: .png, properties: [:]) else {
        print("❌ Error rendering view for \(path)")
        return
    }

    let url = URL(fileURLWithPath: path)
    do {
        try pngData.write(to: url)
        print("✅ Saved \(path) (\(bitmap.pixelsWide)x\(bitmap.pixelsHigh) px, \(pngData.count / 1024) KB)")
    } catch {
        print("❌ Failed writing to \(path): \(error)")
    }
}

// MARK: - Album Art Generator (Stylized Vinyl & Cover Art)

struct SampleArtworkView: View {
    let gradientColors: [Color]
    let style: ArtworkStyle

    enum ArtworkStyle {
        case synthwave
        case cosmic
        case neonSunset
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            switch style {
            case .synthwave:
                // Geometric retro sun & grid
                VStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.yellow, Color.red, Color.purple],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 90, height: 90)
                        .offset(y: -10)
                        .shadow(color: .orange.opacity(0.6), radius: 20)
                    Spacer()
                }

                // Grid lines / horizon
                VStack {
                    Spacer()
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color.cyan.opacity(0.7), Color.blue.opacity(0.1)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: 70)
                }

            case .cosmic:
                // Glowing starburst & planetary circles
                Circle()
                    .fill(Color.cyan.opacity(0.25))
                    .frame(width: 140, height: 140)
                    .offset(x: 40, y: -30)

                Circle()
                    .fill(Color.purple.opacity(0.35))
                    .frame(width: 110, height: 110)
                    .offset(x: -50, y: 20)

                Image(systemName: "sparkles")
                    .font(.system(size: 32))
                    .foregroundColor(.yellow.opacity(0.8))
                    .offset(x: -30, y: -40)

            case .neonSunset:
                Circle()
                    .fill(Color.pink.opacity(0.3))
                    .frame(width: 120, height: 120)
                    .offset(x: -30, y: -20)

                Circle()
                    .fill(Color.orange.opacity(0.3))
                    .frame(width: 100, height: 100)
                    .offset(x: 40, y: 10)

                Image(systemName: "waveform.badge.magnifyingglass")
                    .font(.system(size: 28))
                    .foregroundColor(.white.opacity(0.5))
                    .offset(y: -30)
            }
        }
    }
}

// MARK: - 1. Hero Banner

struct HeroBannerView: View {
    let appIcon: NSImage?

    var body: some View {
        ZStack {
            // Background
            Color(red: 0.07, green: 0.08, blue: 0.11)

            // Ambient background glows
            RadialGradient(
                colors: [Color.red.opacity(0.35), Color.clear],
                center: .init(x: 0.15, y: 0.35),
                startRadius: 20,
                endRadius: 360
            )

            RadialGradient(
                colors: [Color.purple.opacity(0.2), Color.clear],
                center: .init(x: 0.85, y: 0.65),
                startRadius: 20,
                endRadius: 400
            )

            HStack(spacing: 40) {
                // Left Column: Branding and Info
                VStack(alignment: .leading, spacing: 14) {
                    // System badge
                    HStack(spacing: 6) {
                        Image(systemName: "apple.logo")
                            .font(.system(size: 11))
                        Text("macOS 13+ • Ventura • Sonoma • Sequoia")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(.white.opacity(0.85))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.12))
                    .cornerRadius(20)

                    // Title with Icon
                    HStack(spacing: 16) {
                        if let icon = appIcon {
                            Image(nsImage: icon)
                                .resizable()
                                .frame(width: 68, height: 68)
                                .cornerRadius(16)
                                .shadow(color: .red.opacity(0.35), radius: 12, y: 6)
                        } else {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(LinearGradient(colors: [.red, .orange], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 68, height: 68)
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            Text("Ymac Player")
                                .font(.system(size: 38, weight: .heavy, design: .default))
                                .foregroundColor(.white)

                            Text("YouTube Music Menu Bar & Desktop Widgets")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.red.opacity(0.95))
                        }
                    }

                    Text("A lightweight, elegant, and native macOS menu bar companion for YouTube Music with interactive desktop widgets, keyboard shortcuts, media keys, and zero background clutter.")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.white.opacity(0.75))
                        .lineSpacing(3)
                        .frame(maxWidth: 500)

                    // Feature highlights pill grid
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            featurePill(icon: "menubar.rectangle", title: "Status Bar Popover")
                            featurePill(icon: "square.grid.2x2.fill", title: "Interactive Desktop Widgets")
                            featurePill(icon: "globe", title: "10 Languages")
                        }
                        HStack(spacing: 8) {
                            featurePill(icon: "waveform", title: "Live Scrubber")
                            featurePill(icon: "lock.shield", title: "WebKit Sandboxed")
                            featurePill(icon: "play.circle", title: "Now Playing Center")
                        }
                    }
                    .padding(.top, 4)

                    // Badges bottom row
                    HStack(spacing: 10) {
                        tagBadge(text: "Release v1.0.0", color: .red)
                        tagBadge(text: "MIT License", color: .blue)
                        tagBadge(text: "Swift 6 / SwiftUI", color: .purple)
                        tagBadge(text: "Open Source", color: .green)
                    }
                    .padding(.top, 4)
                }
                .padding(.leading, 36)

                Spacer(minLength: 0)

                // Right Column: Floating Preview Card
                VStack(spacing: 14) {
                    // Mini Player Popover Mock
                    VStack(spacing: 8) {
                        HStack {
                            Text("Ymac Player")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                            Spacer()
                            Text("Synthwave & Chill ▾")
                                .font(.system(size: 9.5, weight: .semibold))
                                .foregroundColor(.white.opacity(0.8))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2.5)
                                .background(Color.white.opacity(0.15))
                                .cornerRadius(4)
                        }

                        // Artwork card
                        ZStack(alignment: .bottom) {
                            SampleArtworkView(
                                gradientColors: [Color(red: 0.38, green: 0.12, blue: 0.52), Color(red: 0.08, green: 0.22, blue: 0.62)],
                                style: .synthwave
                            )

                            // Dark gradient overlay
                            LinearGradient(
                                colors: [.clear, .black.opacity(0.85), .black],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(height: 100)

                            VStack(spacing: 4) {
                                Text("Midnight City")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                                Text("M83 • Hurry Up, We're Dreaming")
                                    .font(.system(size: 9))
                                    .foregroundColor(.white.opacity(0.8))

                                // Progress bar
                                HStack(spacing: 4) {
                                    Text("1:42")
                                        .font(.system(size: 8, design: .monospaced))
                                        .foregroundColor(.white.opacity(0.8))
                                    GeometryReader { geo in
                                        ZStack(alignment: .leading) {
                                            Capsule().fill(Color.white.opacity(0.3))
                                            Capsule().fill(Color.red).frame(width: geo.size.width * 0.42)
                                        }
                                    }
                                    .frame(height: 3)
                                    Text("4:03")
                                        .font(.system(size: 8, design: .monospaced))
                                        .foregroundColor(.white.opacity(0.8))
                                }
                                .padding(.top, 2)

                                // Buttons
                                HStack(spacing: 16) {
                                    Image(systemName: "backward.fill").font(.system(size: 11))
                                    Image(systemName: "pause.circle.fill").font(.system(size: 26))
                                    Image(systemName: "forward.fill").font(.system(size: 11))
                                }
                                .foregroundColor(.white)
                                .padding(.top, 2)
                            }
                            .padding(.horizontal, 10)
                            .padding(.bottom, 8)
                        }
                        .frame(width: 220, height: 190)
                        .cornerRadius(12)
                        .clipped()

                        // Reactions
                        HStack(spacing: 14) {
                            Image(systemName: "hand.thumbsup.fill").foregroundColor(.blue).font(.system(size: 12))
                            Image(systemName: "shuffle").foregroundColor(.blue).font(.system(size: 12))
                            Image(systemName: "repeat").foregroundColor(.white.opacity(0.7)).font(.system(size: 12))
                            Image(systemName: "hand.thumbsdown").foregroundColor(.white.opacity(0.7)).font(.system(size: 12))
                        }
                        .padding(.top, 2)
                    }
                    .padding(12)
                    .background(Color(red: 0.14, green: 0.15, blue: 0.19))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.5), radius: 24, y: 10)

                    // Small Widget Pill underneath
                    HStack(spacing: 10) {
                        Image(systemName: "waveform")
                            .foregroundColor(.red)
                            .font(.system(size: 12, weight: .bold))
                        Text("Interactive macOS WidgetKit Extension")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(8)
                }
                .padding(.trailing, 36)
            }
        }
        .frame(width: 1100, height: 440)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.white.opacity(0.14), lineWidth: 1)
        )
        .cornerRadius(18)
    }

    private func featurePill(icon: String, title: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.red)
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 4.5)
        .background(Color.white.opacity(0.08))
        .cornerRadius(6)
    }

    private func tagBadge(text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 10.5, weight: .bold))
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3.5)
            .background(color.opacity(0.15))
            .cornerRadius(5)
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .stroke(color.opacity(0.3), lineWidth: 0.8)
            )
    }
}

// MARK: - 2. Menu Bar Popover Screenshot

struct MenuBarPopoverScreenshotView: View {
    let appIcon: NSImage?

    var body: some View {
        ZStack(alignment: .top) {
            // macOS Desktop background
            LinearGradient(
                colors: [Color(red: 0.12, green: 0.13, blue: 0.18), Color(red: 0.07, green: 0.08, blue: 0.12)],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(spacing: 0) {
                // macOS Menu Bar
                HStack(spacing: 16) {
                    HStack(spacing: 14) {
                        Image(systemName: "apple.logo")
                            .font(.system(size: 13, weight: .semibold))
                        Text("Finder")
                            .font(.system(size: 13, weight: .bold))
                        Text("File").font(.system(size: 13))
                        Text("Edit").font(.system(size: 13))
                        Text("View").font(.system(size: 13))
                        Text("Window").font(.system(size: 13))
                        Text("Help").font(.system(size: 13))
                    }
                    .foregroundColor(.white.opacity(0.9))

                    Spacer()

                    // Status Icons
                    HStack(spacing: 12) {
                        // Active Ymac Icon (highlighted with active popover)
                        ZStack {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white.opacity(0.22))
                                .frame(width: 26, height: 22)
                            Image(systemName: "music.note")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        }

                        Image(systemName: "wifi").font(.system(size: 12))
                        Image(systemName: "switch.2").font(.system(size: 12))
                        Image(systemName: "magnifyingglass").font(.system(size: 12))
                        Text("Tue Sep 22  19:45")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(.white.opacity(0.9))
                }
                .padding(.horizontal, 16)
                .frame(height: 30)
                .background(Color.black.opacity(0.5))

                // Popover Container (anchored under the Ymac icon)
                HStack {
                    Spacer()

                    VStack(spacing: 0) {
                        // Triangle arrow pointing to the icon
                        Image(systemName: "triangle.fill")
                            .font(.system(size: 10))
                            .foregroundColor(Color(red: 0.16, green: 0.17, blue: 0.22))
                            .offset(y: 3)
                            .padding(.trailing, 92)

                        // Main Popover Card
                        VStack(spacing: 10) {
                            // Header
                            HStack(spacing: 6) {
                                Text("Ymac Player")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.white)

                                Spacer()

                                // Playlist picker menu
                                HStack(spacing: 4) {
                                    Text("Synthwave & Chill")
                                        .font(.system(size: 11, weight: .medium))
                                    Image(systemName: "chevron.up.chevron.down")
                                        .font(.system(size: 9))
                                }
                                .foregroundColor(.white.opacity(0.9))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.white.opacity(0.12))
                                .cornerRadius(5)

                                Image(systemName: "globe")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.75))
                                    .frame(width: 24, height: 24)
                            }

                            // Artwork Player (260x260 pt)
                            ZStack(alignment: .bottom) {
                                SampleArtworkView(
                                    gradientColors: [Color(red: 0.38, green: 0.12, blue: 0.52), Color(red: 0.08, green: 0.22, blue: 0.62)],
                                    style: .synthwave
                                )

                                // Gradient overlay
                                LinearGradient(
                                    colors: [.clear, .black.opacity(0.85), .black],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                                .frame(height: 150)

                                // Track text & playback controls
                                VStack(spacing: 8) {
                                    VStack(spacing: 2) {
                                        Text("Midnight City")
                                            .font(.system(size: 13.5, weight: .bold))
                                            .foregroundColor(.white)
                                            .shadow(color: .black.opacity(0.9), radius: 2)

                                        Text("M83 • Hurry Up, We're Dreaming")
                                            .font(.system(size: 11))
                                            .foregroundColor(.white.opacity(0.86))
                                            .shadow(color: .black.opacity(0.9), radius: 2)
                                    }

                                    // Progress bar
                                    VStack(spacing: 2) {
                                        GeometryReader { geo in
                                            ZStack(alignment: .leading) {
                                                Capsule().fill(Color.white.opacity(0.25))
                                                Capsule().fill(Color.red).frame(width: geo.size.width * 0.42)
                                                Circle().fill(Color.white).frame(width: 8, height: 8)
                                                    .offset(x: geo.size.width * 0.42 - 4)
                                            }
                                        }
                                        .frame(height: 4)

                                        HStack {
                                            Text("1:42")
                                            Spacer()
                                            Text("4:03")
                                        }
                                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                        .foregroundColor(.white.opacity(0.9))
                                    }

                                    // Playback controls
                                    ZStack {
                                        HStack(spacing: 22) {
                                            Image(systemName: "backward.fill")
                                                .font(.title3)
                                                .foregroundColor(.white)

                                            Image(systemName: "pause.circle.fill")
                                                .font(.system(size: 40))
                                                .foregroundColor(.white)

                                            Image(systemName: "forward.fill")
                                                .font(.title3)
                                                .foregroundColor(.white)
                                        }

                                        HStack {
                                            Spacer()
                                            Image(systemName: "list.bullet")
                                                .font(.title3)
                                                .foregroundColor(.white)
                                                .padding(.trailing, 4)
                                        }
                                    }
                                }
                                .padding(.horizontal, 12)
                                .padding(.bottom, 10)
                            }
                            .frame(width: 260, height: 260)
                            .cornerRadius(14)
                            .clipped()

                            Divider()
                                .background(Color.white.opacity(0.12))

                            // Reaction Controls
                            HStack {
                                Spacer()
                                Image(systemName: "hand.thumbsup.fill")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                                    .frame(width: 44, height: 38)

                                Spacer()
                                Image(systemName: "shuffle")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                                    .frame(width: 44, height: 38)
                                    .background(Color.blue.opacity(0.18))
                                    .clipShape(Circle())

                                Spacer()
                                Image(systemName: "repeat")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .frame(width: 44, height: 38)

                                Spacer()
                                Image(systemName: "hand.thumbsdown")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .frame(width: 44, height: 38)

                                Spacer()
                            }
                        }
                        .padding(12)
                        .background(Color(red: 0.16, green: 0.17, blue: 0.22))
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.55), radius: 28, y: 14)
                    }
                    .padding(.trailing, 20)
                }
                .padding(.top, 4)

                Spacer()
            }
        }
        .frame(width: 580, height: 500)
    }
}

// MARK: - 3. Desktop Widgets Showcase

struct DesktopWidgetsShowcaseView: View {
    var body: some View {
        ZStack {
            // Wallpaper background
            LinearGradient(
                colors: [Color(red: 0.08, green: 0.1, blue: 0.16), Color(red: 0.05, green: 0.06, blue: 0.09)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Cosmic ambient shapes
            Circle()
                .fill(Color.purple.opacity(0.18))
                .frame(width: 380, height: 380)
                .offset(x: -200, y: -80)

            Circle()
                .fill(Color.red.opacity(0.15))
                .frame(width: 320, height: 320)
                .offset(x: 220, y: 80)

            VStack(spacing: 26) {
                // Title header
                VStack(spacing: 6) {
                    HStack(spacing: 8) {
                        Image(systemName: "square.grid.2x2.fill")
                            .foregroundColor(.red)
                            .font(.system(size: 15, weight: .bold))
                        Text("macOS Sonoma & Sequoia Interactive Desktop Widgets")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }

                    Text("Control playback, switch playlists, and see live progress directly from your desktop via AppIntents.")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                }

                // Widgets Row
                HStack(alignment: .top, spacing: 32) {
                    // Left: Medium Widget (.systemMedium, 340x160)
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Medium Widget (340 × 160)")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white.opacity(0.85))
                            Spacer()
                            Text("Interactive")
                                .font(.system(size: 9.5, weight: .bold))
                                .foregroundColor(.blue)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.15))
                                .cornerRadius(4)
                        }
                        .frame(width: 340)

                        // Medium Widget Component
                        mediumWidget
                            .frame(width: 340, height: 160)
                            .cornerRadius(22)
                            .overlay(
                                RoundedRectangle(cornerRadius: 22)
                                    .stroke(Color.white.opacity(0.18), lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(0.4), radius: 16, y: 8)
                    }

                    // Right: Small Widget (.systemSmall, 160x160)
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Small Widget (160 × 160)")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white.opacity(0.85))
                        }
                        .frame(width: 160)

                        // Small Widget Component
                        smallWidget
                            .frame(width: 160, height: 160)
                            .cornerRadius(22)
                            .overlay(
                                RoundedRectangle(cornerRadius: 22)
                                    .stroke(Color.white.opacity(0.18), lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(0.4), radius: 16, y: 8)
                    }
                }

                // Bottom feature callouts
                HStack(spacing: 24) {
                    featureItem(icon: "bolt.fill", title: "Instant AppIntents", desc: "No app window pops up")
                    featureItem(icon: "arrow.triangle.2.circlepath", title: "App Group Sync", desc: "Live Darwin notification events")
                    featureItem(icon: "sparkles", title: "Zero Background CPU", desc: "Ultra-low power timeline updates")
                }
                .padding(.top, 6)
            }
            .padding(24)
        }
        .frame(width: 820, height: 440)
    }

    private func featureItem(icon: String, title: String, desc: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.red)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                Text(desc)
                    .font(.system(size: 9.5))
                    .foregroundColor(.white.opacity(0.65))
            }
        }
    }

    private var mediumWidget: some View {
        ZStack {
            // Artwork & Gradient
            SampleArtworkView(
                gradientColors: [Color(red: 0.3, green: 0.1, blue: 0.5), Color(red: 0.08, green: 0.15, blue: 0.4)],
                style: .cosmic
            )

            LinearGradient(
                colors: [.black.opacity(0.35), .black.opacity(0.88)],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(spacing: 6) {
                // Top Header Row
                HStack(alignment: .top, spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Image(systemName: "waveform")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.red)
                            Text("Starboy")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .lineLimit(1)
                        }

                        Text("The Weeknd • Daft Punk")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.85))
                            .lineLimit(1)
                    }

                    Spacer(minLength: 0)

                    // Reset/Select playlist icon
                    Image(systemName: "music.note.list")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white.opacity(0.85))
                        .frame(width: 26, height: 26)
                        .background(Color.white.opacity(0.18))
                        .clipShape(Circle())
                }

                Spacer(minLength: 0)

                // Progress Bar
                VStack(spacing: 2) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.white.opacity(0.25))
                            Capsule().fill(Color.red).frame(width: geo.size.width * 0.58)
                        }
                    }
                    .frame(height: 3.5)

                    HStack {
                        Text("2:15")
                        Spacer()
                        Text("3:50")
                    }
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.9))
                }

                // Control buttons
                HStack(spacing: 20) {
                    Image(systemName: "shuffle")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.blue)

                    Spacer()

                    Image(systemName: "backward.fill")
                        .font(.system(size: 13))
                        .foregroundColor(.white)

                    Image(systemName: "pause.circle.fill")
                        .font(.system(size: 26))
                        .foregroundColor(.white)

                    Image(systemName: "forward.fill")
                        .font(.system(size: 13))
                        .foregroundColor(.white)

                    Spacer()

                    Image(systemName: "repeat.1")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.blue)
                }
                .padding(.horizontal, 4)
            }
            .padding(14)
        }
    }

    private var smallWidget: some View {
        ZStack {
            SampleArtworkView(
                gradientColors: [Color(red: 0.45, green: 0.15, blue: 0.25), Color(red: 0.15, green: 0.08, blue: 0.35)],
                style: .neonSunset
            )

            LinearGradient(
                colors: [.black.opacity(0.35), .black.opacity(0.88)],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 3) {
                // Header
                HStack(alignment: .top, spacing: 2) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Blinding Lights")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)

                        Text("The Weeknd")
                            .font(.system(size: 9))
                            .foregroundColor(.white.opacity(0.8))
                            .lineLimit(1)
                    }

                    Spacer(minLength: 0)

                    Image(systemName: "music.note.list")
                        .font(.system(size: 9.5, weight: .bold))
                        .foregroundColor(.white.opacity(0.85))
                        .frame(width: 22, height: 22)
                        .background(Color.black.opacity(0.45))
                        .clipShape(Circle())
                }

                Spacer()

                // Progress Bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.25))
                        Capsule().fill(Color.red).frame(width: geo.size.width * 0.45)
                    }
                }
                .frame(height: 3)

                HStack {
                    Text("1:30")
                    Spacer()
                    Text("3:20")
                }
                .font(.system(size: 8, weight: .semibold, design: .monospaced))
                .foregroundColor(.white.opacity(0.85))

                // Playback Controls
                HStack(spacing: 0) {
                    Image(systemName: "shuffle").font(.system(size: 9.5)).foregroundColor(.white.opacity(0.6))
                    Spacer()
                    Image(systemName: "backward.fill").font(.system(size: 9.5)).foregroundColor(.white)
                    Spacer()
                    Image(systemName: "pause.circle.fill").font(.system(size: 19)).foregroundColor(.white)
                    Spacer()
                    Image(systemName: "forward.fill").font(.system(size: 9.5)).foregroundColor(.white)
                    Spacer()
                    Image(systemName: "repeat").font(.system(size: 9.5)).foregroundColor(.white.opacity(0.6))
                }
                .padding(.top, 2)
            }
            .padding(12)
        }
    }
}

// MARK: - 4. Queue Popover Screenshot

struct QueuePopoverScreenshotView: View {
    var body: some View {
        ZStack {
            // Dark macOS background
            Color(red: 0.1, green: 0.11, blue: 0.15)

            VStack(spacing: 0) {
                // Header badge
                HStack(spacing: 6) {
                    Image(systemName: "list.bullet")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.blue)
                    Text("Live Playing Queue (\"Up Next\")")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.bottom, 12)

                // Popover Box
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Up Next")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                        Spacer()
                        Text("8 tracks")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.horizontal, 10)
                    .padding(.top, 10)

                    Divider()
                        .background(Color.white.opacity(0.12))

                    VStack(alignment: .leading, spacing: 3) {
                        queueRow(title: "Midnight City", artist: "M83", isPlaying: true)
                        queueRow(title: "Resonance", artist: "HOME", isPlaying: false)
                        queueRow(title: "Starboy", artist: "The Weeknd ft. Daft Punk", isPlaying: false)
                        queueRow(title: "Nightcall", artist: "Kavinsky", isPlaying: false)
                        queueRow(title: "Instant Crush", artist: "Daft Punk ft. Julian Casablancas", isPlaying: false)
                        queueRow(title: "Get Lucky", artist: "Daft Punk ft. Pharrell Williams", isPlaying: false)
                        queueRow(title: "After Dark", artist: "Mr.Kitty", isPlaying: false)
                    }
                    .padding(.horizontal, 6)
                    .padding(.bottom, 10)
                }
                .frame(width: 290)
                .background(Color(red: 0.16, green: 0.17, blue: 0.22))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.5), radius: 24, y: 10)
            }
        }
        .frame(width: 480, height: 460)
    }

    private func queueRow(title: String, artist: String, isPlaying: Bool) -> some View {
        HStack(spacing: 8) {
            if isPlaying {
                Image(systemName: "play.fill")
                    .font(.system(size: 9))
                    .foregroundColor(.blue)
                    .frame(width: 14)
            } else {
                Circle()
                    .fill(Color.clear)
                    .frame(width: 14, height: 14)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: isPlaying ? .semibold : .regular))
                    .foregroundColor(isPlaying ? .white : .white.opacity(0.9))
                    .lineLimit(1)

                Text(artist)
                    .font(.system(size: 10))
                    .foregroundColor(isPlaying ? .white.opacity(0.8) : .white.opacity(0.55))
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            if isPlaying {
                Image(systemName: "waveform")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.blue)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(isPlaying ? Color.blue.opacity(0.2) : Color.clear)
        .cornerRadius(6)
    }
}

// MARK: - 5. Context Menu Screenshot

struct ContextMenuScreenshotView: View {
    var body: some View {
        ZStack(alignment: .topLeading) {
            // Dark macOS background
            Color(red: 0.1, green: 0.11, blue: 0.15)

            VStack(alignment: .leading, spacing: 14) {
                // Header
                HStack(spacing: 8) {
                    Image(systemName: "contextualmenu.and.cursor")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.blue)
                    Text("Menu Bar Right-Click Context Menu & 10 Languages")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                }

                // Main Menu + Submenu side-by-side
                HStack(alignment: .top, spacing: 2) {
                    // Main Context Menu
                    VStack(alignment: .leading, spacing: 2) {
                        menuItem(icon: "globe", title: "Language", hasSubmenu: true, isHovered: true)
                        menuSeparator
                        menuItem(icon: "books.vertical.fill", title: "Library", hasSubmenu: true)
                        menuSeparator
                        menuItem(icon: "checkmark", title: "Launch at Login", isChecked: true)
                        menuSeparator
                        menuItem(icon: "info.circle", title: "About Ymac Player")
                        menuSeparator
                        menuItem(icon: "power", title: "Quit Ymac Player", shortcut: "⌘Q")
                    }
                    .padding(5)
                    .frame(width: 190)
                    .background(Color(red: 0.18, green: 0.19, blue: 0.23).opacity(0.95))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.18), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.4), radius: 14, y: 6)

                    // Language Submenu
                    VStack(alignment: .leading, spacing: 2) {
                        subMenuItem(title: "English", isChecked: true)
                        subMenuItem(title: "Русский (Russian)")
                        subMenuItem(title: "Español (Spanish)")
                        subMenuItem(title: "Deutsch (German)")
                        subMenuItem(title: "Français (French)")
                        subMenuItem(title: "Italiano (Italian)")
                        subMenuItem(title: "Português (Portuguese)")
                        subMenuItem(title: "Türkçe (Turkish)")
                        subMenuItem(title: "Українська (Ukrainian)")
                        subMenuItem(title: "日本語 (Japanese)")
                    }
                    .padding(5)
                    .frame(width: 175)
                    .background(Color(red: 0.18, green: 0.19, blue: 0.23).opacity(0.95))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.18), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.4), radius: 14, y: 6)
                }
            }
            .padding(24)
        }
        .frame(width: 520, height: 420)
    }

    private var menuSeparator: some View {
        Divider()
            .background(Color.white.opacity(0.12))
            .padding(.vertical, 2)
            .padding(.horizontal, 4)
    }

    private func menuItem(icon: String, title: String, hasSubmenu: Bool = false, isHovered: Bool = false, isChecked: Bool = false, shortcut: String? = nil) -> some View {
        HStack(spacing: 8) {
            if isChecked {
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 12)
            } else {
                Spacer().frame(width: 12)
            }

            Text(title)
                .font(.system(size: 12))
                .foregroundColor(.white)

            Spacer()

            if let sc = shortcut {
                Text(sc)
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.55))
            } else if hasSubmenu {
                Image(systemName: "chevron.right")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white.opacity(0.65))
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4.5)
        .background(isHovered ? Color.blue : Color.clear)
        .cornerRadius(5)
    }

    private func subMenuItem(title: String, isChecked: Bool = false) -> some View {
        HStack(spacing: 8) {
            if isChecked {
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 12)
            } else {
                Spacer().frame(width: 12)
            }

            Text(title)
                .font(.system(size: 12))
                .foregroundColor(.white)

            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3.5)
        .background(isChecked ? Color.white.opacity(0.12) : Color.clear)
        .cornerRadius(5)
    }
}

// MARK: - Main Runner

@MainActor
func main() {
    print("🎨 Starting asset generation for Ymac Player...")

    let iconPath = "YmacPlayer/Assets.xcassets/AppIcon.appiconset/icon_512x512@2x.png"
    let appIcon = NSImage(contentsOfFile: iconPath)

    // 1. Hero Banner
    saveView(
        HeroBannerView(appIcon: appIcon),
        size: CGSize(width: 1100, height: 440),
        to: "docs/assets/hero_banner.png"
    )

    // 2. Menu Bar Popover
    saveView(
        MenuBarPopoverScreenshotView(appIcon: appIcon),
        size: CGSize(width: 580, height: 500),
        to: "docs/assets/menu_bar_popover.png"
    )

    // 3. Desktop Widgets
    saveView(
        DesktopWidgetsShowcaseView(),
        size: CGSize(width: 820, height: 440),
        to: "docs/assets/desktop_widgets.png"
    )

    // 4. Queue Popover
    saveView(
        QueuePopoverScreenshotView(),
        size: CGSize(width: 480, height: 460),
        to: "docs/assets/queue_popover.png"
    )

    // 5. Context Menu
    saveView(
        ContextMenuScreenshotView(),
        size: CGSize(width: 520, height: 420),
        to: "docs/assets/context_menu.png"
    )

    print("🎉 All 5 visual assets generated successfully!")
}

MainActor.assumeIsolated {
    main()
}
