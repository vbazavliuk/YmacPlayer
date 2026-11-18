import SwiftUI
import WebKit

// MARK: - Hidden Web View Representable

/// A SwiftUI wrapper for embedding and managing the shared `WKWebView` instance of Ymac Player.
struct HiddenWebView: NSViewRepresentable {

    @MainActor
    private static var activeHostID: UUID?

    final class Coordinator {
        let hostID = UUID()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> WKWebView {
        let webView = YTMController.shared.webView
        Self.activeHostID = context.coordinator.hostID
        webView.window?.makeFirstResponder(nil)
        webView.translatesAutoresizingMaskIntoConstraints = true
        webView.autoresizingMask = [.width, .height]
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
    }

    func sizeThatFits(_ proposal: ProposedViewSize, nsView: WKWebView, context: Context) -> CGSize? {
        let width = max(276, proposal.width ?? 276)
        let height = max(200, proposal.height ?? 380)
        return CGSize(width: width, height: height)
    }

    /// Re-attaches the webView to the background window when the popover or browser view closes.
    @MainActor
    static func dismantleNSView(_ nsView: WKWebView, coordinator: Coordinator) {
        guard Self.activeHostID == coordinator.hostID else { return }
        Self.activeHostID = nil
        nsView.window?.makeFirstResponder(nil)
        nsView.translatesAutoresizingMaskIntoConstraints = true
        nsView.autoresizingMask = [.width, .height]
        YTMController.shared.attachToBackgroundWindow()
    }
}
