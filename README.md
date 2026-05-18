<div align="center">
  <h1>🚀 Leap</h1>
  <p>A lightweight, elegant macOS menu bar utility for multi-monitor power users.</p>
  <p><a href="#english">English</a> | <a href="#中文">中文</a></p>
</div>

---

<h2 id="english">English</h2>

## ✨ Features

- **Instant Cursor Jumping**: Bind custom global keyboard shortcuts (e.g., `⌥ + 1`, `⌥ + 2`) to instantly snap your mouse cursor to the center of any connected monitor.
- **Dynamic Display Syncing**: The preferences perfectly and dynamically adapt when you plug or unplug external displays—in real-time.
- **Clipboard History**: Automatically records your text and image clipboard history. Click on any item to instantly paste it into your previous app.
- **Native Image Preview**: Hover over any copied image to see a magnifying glass, and click to open a fast, native macOS preview window (with full-screen support).
- **Silent & Unobtrusive**: Lives purely in your macOS Menu Bar. No Dock icon, no distractions.
- **Extensible Architecture**: Built with modern Swift, SwiftUI, and a highly modularized domain-driven architecture.

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
2. Click the icon and select **偏好设置... (Preferences...)** to bind your monitor jumping shortcuts.
3. Select **剪切板历史... (Clipboard History...)** to view your recent copied text and images.
4. Close the window and enjoy! Your cursor will now "leap" across screens instantly, and your clipboard is always safely backed up.

## 🏗 Architecture

Leap is open-sourced with a modern, decoupled codebase:
- `App/`: Core lifecycles (`AppDelegate`).
- `Managers/`: High-level singleton dispatchers (`HotKeyManager` for Carbon events, `CursorManager` for screen coordinate math, `ClipboardManager` for pasteboard tracking, `MenuManager` for status bar UI).
- `UI/`: SwiftUI-first preferences windows and responsive components.
- `Models/ & Store/`: Persistence and state-binding layers.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

<h2 id="中文">中文</h2>

## ✨ 特性

- **瞬间光标跳转**：绑定自定义全局快捷键（例如 `⌥ + 1`、`⌥ + 2`），即可将鼠标光标瞬间移动到任何连接的显示器中心。
- **动态显示器同步**：当您插入或拔出外接显示器时，偏好设置会实时、完美地动态适配。
- **剪贴板历史记录**：自动记录您复制的文本和图片。点击任何历史记录项即可瞬间将其粘贴回上一个应用。
- **原生图片预览**：鼠标悬停在复制的图片记录上即可显示放大镜图标，点击可打开极速的 macOS 原生预览窗口（支持原生全屏模式）。
- **安静无感**：纯粹驻留在您的 macOS 菜单栏中。没有 Dock 栏图标，没有打扰。
- **易扩展架构**：基于现代 Swift、SwiftUI 和高度模块化的领域驱动架构构建。

## 📦 安装

1. 克隆此仓库到本地：
   ```bash
   git clone https://github.com/ElioChanSpace/Leap.git
   ```
2. 在 **Xcode** 中打开 `Leap.xcodeproj`。
3. 选择 `Leap` scheme 并按下 `Cmd + R` 编译并运行！

> **注意**：由于 Leap 使用了底层的 macOS API hook 来拦截全局快捷键并操作光标 `CGEvent`，在首次运行时需要您授予**辅助功能（Accessibility）**权限。
> 
> 请前往 **系统设置 > 隐私与安全性 > 辅助功能** -> 允许 Leap。

## 🎛 使用方法

1. 在您的 macOS 菜单栏中找到 `Leap` 图标（带光芒的光标）。
2. 点击图标并选择 **偏好设置...** 来绑定您的显示器跳转快捷键。
3. 选择 **剪切板历史...** 来查看您最近复制的文本和图片，点击图片即可原生放大预览。
4. 关闭窗口即可体验！您的光标现在可以瞬间跨屏“跳跃”，并且您的剪贴板也会被安全地记录下来。

## 🏗 架构

Leap 是一个开源项目，代码库现代且解耦：
- `App/`: 核心生命周期（`AppDelegate`）。
- `Managers/`: 高层单例分发器（用于 Carbon 事件的 `HotKeyManager`，用于屏幕坐标计算的 `CursorManager`，用于监听剪切板的 `ClipboardManager`，用于状态栏 UI 的 `MenuManager`）。
- `UI/`: 采用 SwiftUI 构建的偏好设置窗口和响应式组件。
- `Models/ & Store/`: 持久化和状态绑定层。

## 📄 许可证

本项目基于 MIT 许可证开源 - 详情请查看 [LICENSE](LICENSE) 文件。
