<div align="center">
  <h1>🚀 Leap</h1>
  <p>A lightweight, elegant macOS menu bar utility for multi-monitor power users.</p>
</div>

## ✨ Features

- **Instant Cursor Jumping**: Bind custom global keyboard shortcuts (e.g., `⌥ + 1`, `⌥ + 2`) to instantly snap your mouse cursor to the center of any connected monitor.
- **Dynamic Display Syncing**: The preferences perfectly and dynamically adapt when you plug or unplug external displays—in real-time.
- **Silent & Unobtrusive**: Lives purely in your macOS Menu Bar. No Dock icon, no distractions.
- **Extensible Architecture**: Built with modern Swift, SwiftUI, and a highly modularized domain-driven architecture, making it extremely easy to extend (Screenshot and Clipboard features on the roadmap!).

## 📦 Installation

1. Clone this repository to your local machine:
   ```bash
   git clone https://github.com/ElioChanSpace/Leap.git
   ```
2. Open `Leap.xcodeproj` in **Xcode**.
3. Select the `Leap` scheme and hit `Cmd + R` to Build and Run!

> **Note**: Because Leap uses low-level macOS API hooks to intercept global shortcuts and manipulate your cursor `CGEvent`, you will need to grant it **Accessibility** permissions on the first run.
> 
> Go to **System Settings > Privacy & Security > Accessibility** -> allow Leap.

## 🎛 Usage

1. Look for the `Leap` icon (cursor with rays) in your macOS menu bar.
2. Click the icon and select **偏好设置... (Preferences...)**
3. In the settings window, click on the shortcut recorder fields for each display.
4. Press your desired key combination (e.g., `Option + 1`, `Option + 2`).
5. Close the window and enjoy! Your cursor will now "leap" across screens instantly.

## 🏗 Architecture

Leap is open-sourced with a modern, decoupled codebase:
- `App/`: Core lifecycles (`AppDelegate`).
- `Managers/`: High-level singleton dispatchers (`HotKeyManager` for Carbon events, `CursorManager` for screen coordinate math, `MenuManager` for status bar UI).
- `UI/`: SwiftUI-first preferences windows and responsive components.
- `Models/ & Store/`: Persistence and state-binding layers.

## 🤝 Contributing

Contributions, issues, and feature requests are always welcome! 
We are looking forward to scaling this tool into a fully-fledged utility belt with Screenshot parsing and Clipboard history tracking.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
