# Ymac Player v1.0.0 — Release Notes

We are thrilled to announce the initial official release of **Ymac Player (v1.0.0)** — a sleek, native macOS companion for YouTube Music built with SwiftUI, AppIntents, and WidgetKit.

---

## 🌟 Highlights

- **🎧 Menu Bar Music Popover:** Access YouTube Music instantly from the macOS status bar. View high-resolution album artwork, track title, artist, seekable progress slider, and one-click playback controls.
- **📱 macOS Sonoma & Sequoia Desktop Widgets:** Control playback and switch between your favorite playlists directly from your desktop with interactive widgets (`systemSmall` and `systemMedium`). Zero application window pops up!
- **🌐 10 Built-in Languages:** Fully localized interface supporting English, Русский, Español, Deutsch, Français, Italiano, Português, Türkçe, Українська, and 日本語.
- **⚡️ Native Media Keys & Control Center:** Seamlessly integrated with `MPNowPlayingInfoCenter` and `MPRemoteCommandCenter`. Control playback with your Mac's physical media keys, Touch Bar, and Lock Screen.
- **🔒 WebKit Sandboxed Core:** Pure native Swift & SwiftUI application with a sandboxed WebKit engine. Zero Electron overhead, minimal RAM footprint, and complete privacy isolation.
- **🚀 Autostart at Login:** Optionally launch silently at login via macOS `SMAppService`.

---

## 📥 Downloads & Assets

| Asset | Format | Description |
| :--- | :--- | :--- |
| **`YmacPlayer-1.0.0.dmg`** | Apple Disk Image | Drag-and-drop installer for macOS 13+ |
| **`YmacPlayer-1.0.0.zip`** | Compressed Archive | Portable standalone `.app` bundle |
| **`SHA256SUMS.txt`** | Text | Cryptographic checksums for verifying asset integrity |

---

## 💻 System Requirements

- **Operating System:** macOS 14.0 (Sonoma), macOS 15.0 (Sequoia), or later.
- **Architecture:** Apple Silicon (M1/M2/M3/M4) & Intel (Universal Binary compatible).

---

## 🛠 Installation Instructions

1. Download **`YmacPlayer-1.0.0.dmg`** (or `YmacPlayer-1.0.0.zip`) from Assets below.
2. Double-click the `.dmg` file and drag **Ymac Player.app** into your **Applications** folder.
3. Open Terminal and run this one-time command (to clear Apple Gatekeeper quarantine on open-source binaries):
   ```bash
   xattr -cr /Applications/YmacPlayer.app
   ```
   *(Alternatively: Right-click `YmacPlayer.app` in Finder and select **Open**).*
4. Launch **Ymac Player**, click the menu bar icon, and click **Login** to connect your YouTube Music account!

---

## 🎛 Adding Desktop Widgets

1. Right-click your macOS desktop and select **Edit Widgets...** (or open Notification Center and click **Edit Widgets**).
2. Search for **Ymac Player** in the widget gallery.
3. Drag either the **Small** or **Medium** widget onto your desktop.
4. Enjoy instant interactive playback control!

---

## 📋 Full Changelog

- Initial public release of Ymac Player v1.0.0.
- Implemented `YTMController` with JavaScript bridge for YouTube Music Web API.
- Implemented App Group IPC (`group.com.ymacplayer`) and Darwin Notifications for instant synchronization between the main app and widget extension.
- Added AppIntents for widget playback commands: `TogglePlayIntent`, `NextTrackIntent`, `PreviousTrackIntent`, `ToggleShuffleIntent`, `ToggleRepeatIntent`, `SelectPlaylistIntent`, and `ResetPlaylistIntent`.
- Added localized menus and status notifications across 10 languages.
- Configured automated release packaging (`scripts/build_release.sh`).
