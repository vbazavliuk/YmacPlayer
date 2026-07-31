# Ymac Player 🎵

**Ymac Player** is a lightweight, background-native macOS menu bar application and desktop widget system designed for **YouTube Music**. It brings seamless playback controls, playlist selection, queue management, and system media integration without cluttering your workspace.

---

## ✨ Key Features

* 📍 **Menu Bar Control**: Access full player controls, album artwork, track seeking, and queue navigation directly from the status bar.
* 🧩 **Interactive Desktop Widgets**: Native macOS Widgets powered by `AppIntents` allowing you to play/pause, skip tracks, toggle shuffle/repeat, and switch playlists straight from your desktop or Notification Center.
* ⚡ **Seamless Background Playback**: WebKit engine hosted inside an invisible background window container to prevent macOS process suspension during popover closure.
* 🎧 **System Media Integration**: Native `MPNowPlayingInfoCenter` and `MPRemoteCommandCenter` integration — fully compatible with macOS Control Center, hardware media keys, and Lock Screen controls.
* 🌐 **Multi-Language Support (10 Languages)**: Instant localized UI switching between English, Deutsch, Українська, Русский, Español, Português, Italiano, Français, Română, and Polski.
* 🚀 **Launch at Login**: Automatic background startup via `ServiceManagement` (`SMAppService`).

---

## 🛠 Tech Stack & Architecture

* **Frameworks**: SwiftUI, AppKit, WebKit, WidgetKit, AppIntents, ServiceManagement, MediaPlayer.
* **Architecture**: Single-instance `@MainActor` state controller (`YTMController`) communicating with an injected JavaScript bridge (`syncScript`) inside a `WKWebView`.
* **Inter-Process Communication (IPC)**: Darwin Notifications (`CFNotificationCenter`) and shared App Groups (`group.com.ymacplayer`) for instant UI synchronization between the main app and Widget Extension.
* **Language Mode**: Swift 6 Concurrency strict mode compatible.

---

## 📋 Requirements

* **macOS**: 13.0 (Ventura) or later *(Control Widgets require macOS 15.0+)*.
* **Xcode**: 15.0 or later.
* **Swift**: 5.9 / 6.0.

---

## 🚀 Getting Started

### 1. Clone the Repository
```bash
git clone [https://github.com/your-username/YmacPlayer.git](https://github.com/your-username/YmacPlayer.git)
cd YmacPlayer
