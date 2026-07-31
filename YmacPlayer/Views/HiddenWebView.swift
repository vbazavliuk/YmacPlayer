import SwiftUI
import WebKit

// MARK: - Hidden Web View Representable

/// A SwiftUI wrapper for embedding and managing the shared `WKWebView` instance of Ymac Player.
struct HiddenWebView: NSViewRepresentable {

    func makeNSView(context: Context) -> WKWebView {
        let webView = YTMController.shared.webView
        webView.window?.makeFirstResponder(nil)
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
    }

    /// Re-attaches the webView to the background window when the popover or browser view closes.
    @MainActor
    static func dismantleNSView(_ nsView: WKWebView, coordinator: ()) {
        YTMController.shared.attachToBackgroundWindow()
    }
}
