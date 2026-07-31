import SwiftUI

// MARK: - Queue Popover View

/// A popover view displaying the upcoming track queue in Ymac Player.
struct QueuePopoverView: View {

    @EnvironmentObject private var controller: YTMController
    @Binding var isPresented: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(LocalizedStrings.upNext(controller.currentLanguage))
                .font(.caption.bold())
                .padding(.horizontal, 8)
                .padding(.top, 8)

            Divider()

            if controller.queue.isEmpty {
                Text(LocalizedStrings.emptyQueue(controller.currentLanguage))
                    .font(.caption)
                    .foregroundColor(.secondary)
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
                        .padding(.horizontal, 4)
                        .padding(.bottom, 8)
                    }
                    .frame(width: 250, height: 260)
                    .onAppear {
                        if let selected = controller.queue.first(
                            where: { $0.isSelected }
                        ) {
                            proxy.scrollTo(
                                selected.id,
                                anchor: .center
                            )
                        }
                    }
                }
            }
        }
        .frame(width: 260)
    }
}
