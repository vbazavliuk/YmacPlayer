import AppKit
import SwiftUI
import ServiceManagement

// MARK: - Menu Bar Delegate

/// The main application delegate responsible for managing the macOS menu bar status item, popover, and context menu for Ymac Player.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusItem: NSStatusItem!
    private var popover: NSPopover!

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupPopover()
        setupStatusItem()
    }

    // MARK: - Setup

    /// Initializes and configures the main popup popover.
    private func setupPopover() {
        let popover = NSPopover()

        popover.contentSize = NSSize(width: 300, height: 390)
        popover.behavior = .transient

        popover.contentViewController = NSHostingController(
            rootView: MainWidgetView()
                .environmentObject(YTMController.shared)
        )

        self.popover = popover
    }

    /// Sets up the system status bar item and mouse click listeners.
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(
            withLength: NSStatusItem.squareLength
        )

        guard let button = statusItem.button else {
            return
        }

        button.image = NSImage(
            systemSymbolName: "music.note",
            accessibilityDescription: "Ymac Player"
        )

        button.action = #selector(statusItemClicked(_:))
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        button.target = self
    }

    // MARK: - Status Bar Actions

    @objc private func statusItemClicked(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else {
            return
        }

        if event.type == .rightMouseUp {
            showContextMenu(for: sender, event: event)
        } else {
            togglePopover()
        }
    }

    private func togglePopover() {
        guard let button = statusItem.button else {
            return
        }

        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(
                relativeTo: button.bounds,
                of: button,
                preferredEdge: .minY
            )

            NSApp.activate()
        }
    }

    // MARK: - Context Menu Setup

    /// Constructs and displays the right-click context menu.
    private func showContextMenu(for button: NSStatusBarButton, event: NSEvent) {
        let controller = YTMController.shared
        let language = controller.currentLanguage

        let menu = NSMenu()

        addLanguageMenu(to: menu, currentLanguage: language)
        menu.addItem(NSMenuItem.separator())

        addLibraryMenu(
            to: menu,
            controller: controller,
            language: language
        )
        menu.addItem(NSMenuItem.separator())

        addAutostartItem(to: menu, language: language)
        menu.addItem(NSMenuItem.separator())

        addAboutItem(to: menu, language: language)
        menu.addItem(NSMenuItem.separator())

        addQuitItem(to: menu, language: language)

        NSMenu.popUpContextMenu(menu, with: event, for: button)
    }

    private func addLanguageMenu(
        to menu: NSMenu,
        currentLanguage: AppLanguage
    ) {
        let submenu = NSMenu()

        for language in AppLanguage.allCases {
            let item = NSMenuItem(
                title: language.title,
                action: #selector(changeLanguage(_:)),
                keyEquivalent: ""
            )

            item.target = self
            item.representedObject = language
            item.state = language == currentLanguage ? .on : .off

            submenu.addItem(item)
        }

        let item = NSMenuItem(
            title: LocalizedStrings.languageMenuTitle(currentLanguage),
            action: nil,
            keyEquivalent: ""
        )

        item.image = NSImage(
            systemSymbolName: "globe",
            accessibilityDescription: nil
        )

        item.submenu = submenu
        menu.addItem(item)
    }

    private func addLibraryMenu(
        to menu: NSMenu,
        controller: YTMController,
        language: AppLanguage
    ) {
        let submenu = NSMenu()

        let favoritePlaylistsItem = NSMenuItem(
            title: LocalizedStrings.favoritePlaylistsCategoryTitle(language),
            action: #selector(selectFavoritePlaylistsCategory(_:)),
            keyEquivalent: ""
        )

        favoritePlaylistsItem.target = self
        favoritePlaylistsItem.state =
            controller.libraryFilter == .favoritePlaylists ? .on : .off

        submenu.addItem(favoritePlaylistsItem)

        let playlistsItem = NSMenuItem(
            title: LocalizedStrings.playlistsCategoryTitle(language),
            action: #selector(selectPlaylistsCategory(_:)),
            keyEquivalent: ""
        )

        playlistsItem.target = self
        playlistsItem.state =
            controller.libraryFilter == .playlists ? .on : .off

        submenu.addItem(playlistsItem)

        let libraryItem = NSMenuItem(
            title: LocalizedStrings.libraryMenuTitle(language),
            action: nil,
            keyEquivalent: ""
        )

        libraryItem.image = NSImage(
            systemSymbolName: "building.columns",
            accessibilityDescription: nil
        )

        libraryItem.submenu = submenu
        menu.addItem(libraryItem)
    }

    private func addAutostartItem(
        to menu: NSMenu,
        language: AppLanguage
    ) {
        let item = NSMenuItem(
            title: LocalizedStrings.autostartMenuTitle(language),
            action: #selector(toggleAutostart(_:)),
            keyEquivalent: ""
        )

        item.image = NSImage(
            systemSymbolName: "power",
            accessibilityDescription: nil
        )

        item.target = self

        if #available(macOS 13.0, *) {
            item.state = SMAppService.mainApp.status == .enabled ? .on : .off
        }

        menu.addItem(item)
    }

    private func addAboutItem(
        to menu: NSMenu,
        language: AppLanguage
    ) {
        let item = NSMenuItem(
            title: LocalizedStrings.aboutMenuTitle(language),
            action: #selector(showAboutWindow),
            keyEquivalent: ""
        )

        item.image = NSImage(
            systemSymbolName: "info.circle",
            accessibilityDescription: nil
        )

        item.target = self
        menu.addItem(item)
    }

    private func addQuitItem(
        to menu: NSMenu,
        language: AppLanguage
    ) {
        let item = NSMenuItem(
            title: LocalizedStrings.quitApp(language),
            action: #selector(quitApp),
            keyEquivalent: "q"
        )

        item.target = self
        menu.addItem(item)
    }

    // MARK: - Menu Handlers

    @objc private func changeLanguage(_ sender: NSMenuItem) {
        guard let language = sender.representedObject as? AppLanguage else {
            return
        }

        YTMController.shared.setLanguage(language)
    }

    @objc private func selectFavoritePlaylistsCategory(_ sender: NSMenuItem) {
        YTMController.shared.setLibraryFilter(.favoritePlaylists)
    }

    @objc private func selectPlaylistsCategory(_ sender: NSMenuItem) {
        YTMController.shared.setLibraryFilter(.playlists)
    }

    @objc private func toggleAutostart(_ sender: NSMenuItem) {
        guard #available(macOS 13.0, *) else {
            return
        }

        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            print("Failed to toggle autostart: \(error)")
        }
    }

    @objc private func showAboutWindow() {
        let alert = NSAlert()

        alert.messageText = "Ymac Player"
        alert.informativeText = """
        Version 1.0.0

        A lightweight, background-native macOS status bar player and desktop widget for YouTube Music.

        Key Features:
        • Menu Bar Popover: Full player controls, track seeker, and queue viewer.
        • Interactive Desktop Widgets: Control playback and switch playlists directly from macOS Widgets via AppIntents.
        • System Media Integration: Full support for Control Center, Now Playing metadata, and media keys.
        • Multi-Language Support: Available in 10 languages with real-time UI language switching.
        • Background Web Engine: Runs in a dedicated background container to ensure uninterrupted audio playback.

        Built with SwiftUI, WebKit, WidgetKit, and AppIntents.
        """
        alert.alertStyle = .informational
        alert.icon = NSImage(
            systemSymbolName: "music.note.house.fill",
            accessibilityDescription: "Ymac Player"
        )

        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
