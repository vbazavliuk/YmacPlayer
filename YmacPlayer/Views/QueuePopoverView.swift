import SwiftUI

// MARK: - Queue Popover View

/// A popover view displaying the upcoming track queue in Ymac Player.
struct QueuePopoverView: View {

    @EnvironmentObject private var controller: YTMController
    @Binding var isPresented: Bool

    private var selectedTrackId: String? {
        controller.queue.first(where: { $0.isSelected })?.id
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(LocalizedStrings.upNext(controller.currentLanguage))
                .font(.caption.bold())
                .padding(.horizontal, 10)
                .padding(.top, 8)

            Divider()

            if controller.queue.isEmpty {
                Text(LocalizedStrings.emptyQueue(controller.currentLanguage))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 72, alignment: .center)
                    .padding(12)
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(controller.queue) { track in
                                Button {
                                    controller.playQueueItem(
                                        at: track.originalIndex
                                    )

                                    isPresented = false
                                } label: {
                                    HStack(spacing: 6) {
                                        if track.isSelected {
                                            Image(systemName: "play.fill")
                                                .font(.system(size: 9))
                                                .foregroundColor(.blue)
                                                .frame(width: 12)
                                        } else {
                                            Circle()
                                                .fill(Color.clear)
                                                .frame(width: 12, height: 12)
                                        }

                                        VStack(
                                            alignment: .leading,
                                            spacing: 2
                                        ) {
                                            Text(track.title)
                                                .font(.system(
                                                    size: 12,
                                                    weight: track.isSelected
                                                        ? .semibold
                                                        : .regular
                                                ))
                                                .lineLimit(1)

                                            if !track.artist.isEmpty {
                                                Text(track.artist)
                                                    .font(.system(size: 10))
                                                    .foregroundColor(.secondary)
                                                    .lineLimit(1)
                                            }
                                        }

                                        Spacer(minLength: 0)
                                    }
                                    .contentShape(Rectangle())
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 5)
                                    .background(
                                        track.isSelected
                                            ? Color.blue.opacity(0.14)
                                            : Color.clear
                                    )
                                    .cornerRadius(6)
                                }
                                .buttonStyle(.plain)
                                .id(track.id)
                            }
                        }
                        .padding(.horizontal, 6)
                        .padding(.bottom, 8)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 260)
                    .onAppear {
                        scrollToSelected(using: proxy, animated: false)
                    }
                    .onChange(of: selectedTrackId) { _, _ in
                        scrollToSelected(using: proxy, animated: true)
                    }
                }
            }
        }
        .frame(width: 260)
    }

    private func scrollToSelected(using proxy: ScrollViewProxy, animated: Bool) {
        guard let targetId = selectedTrackId else { return }
        DispatchQueue.main.async {
            if animated {
                withAnimation(.easeInOut(duration: 0.2)) {
                    proxy.scrollTo(targetId, anchor: .center)
                }
            } else {
                proxy.scrollTo(targetId, anchor: .center)
            }
        }
    }
}
