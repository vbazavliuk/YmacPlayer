# Ymac Player v1.1.0 — Release Notes

**Ymac Player v1.1.0** delivers full compatibility with YouTube Music's updated player DOM, reliable desktop WidgetKit integration without 7-day profile expiration, queue deduplication, and rock-solid playlist persistence.

---

## 🌟 What's New in v1.1.0

- **🎛 Full YouTube Music Wiz & ShadyDOM Support:** Supports both classic `<ytmusic-player-bar>` (including ShadyDOM) and the newer `<ytmusic-miniplayer>` / `<ytmusic-wiz-player-controls>` player UI so **Play/Pause, Next, Previous, Like, Dislike, Shuffle, and Repeat (Off / All / One)** click and sync accurately in real signed-in sessions.
- **📋 Deduplicated Track Queue:** Filters hidden `#counterpart-renderer[hidden]` AV duplicates inside `<ytmusic-playlist-panel-video-wrapper-renderer>` so tracks and official video counterparts never appear twice in *Up Next*.
- **🔖 Persistent Playlist Selection & Full Library Support:** Resolves active playlists across URLs, `#movie_player.getPlaylistId()`, and queue headers, normalizes `VL` browse prefixes, preserves the full `/library/playlists` list while playing tracks, and keeps your chosen playlist selected across SPA home navigation.
- **🧩 Reliable Desktop Widgets & Non-Expiring Signing:** Configured App Group IPC (`9R2Z2PT297.group.com.ymacplayer`), real-time countdown & artwork sync, interactive `AppIntents`, and CommandLineTools fallback signing without 7-day `embedded.provisionprofile` expiration.
- **🖼 Crisp 16:9 Artwork Cropping & Embedded Browser Fix:** Fixes wide video thumbnails overflowing the compact popover overlay and allows trusted clicks inside the embedded browser (`🌐`) to start playback naturally.
- **🧪 Automated Test Suite (`Tests/run_tests.sh`):** Added 1,000+ unit & `WKWebView` integration assertions covering models, 10 localizations, widget intents, and both YouTube Music DOM architectures.

---

## 📥 Downloads & Assets

| Asset | Format | Description |
| :--- | :--- | :--- |
| **`YmacPlayer-1.1.0.dmg`** | Apple Disk Image | Drag-and-drop installer for macOS 14+ |
| **`YmacPlayer-1.1.0.zip`** | Compressed Archive | Portable standalone `.app` bundle |
| **`SHA256SUMS.txt`** | Text | Cryptographic checksums for verifying asset integrity |

---

## 💻 System Requirements

- **Operating System:** macOS 14.0 or later.
- **Architecture:** Apple Silicon (`arm64`) & Intel compatible.

---

## 🛠 Installation Instructions

1. Download **`YmacPlayer-1.1.0.dmg`** (or `YmacPlayer-1.1.0.zip`) from Assets below.
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
- Implemented App Group IPC (`9R2Z2PT297.group.com.ymacplayer`) and Darwin Notifications for instant synchronization between the main app and widget extension.
- Added AppIntents for widget playback commands: `TogglePlayIntent`, `NextTrackIntent`, `PreviousTrackIntent`, `ToggleShuffleIntent`, `ToggleRepeatIntent`, `SelectPlaylistIntent`, and `ResetPlaylistIntent`.
- Added localized menus and status notifications across 10 languages.
- Configured automated release packaging (`scripts/build_release.sh`).
