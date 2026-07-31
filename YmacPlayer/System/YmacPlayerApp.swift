import SwiftUI

// MARK: - Application Entry Point

/// The main entry point for the Ymac Player macOS application.
@main
struct YmacPlayerApp: App {

    @NSApplicationDelegateAdaptor(AppDelegate.self)
    private var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
