import Cocoa
import SwiftUI

class MenuManager: NSObject {
    static let shared = MenuManager()

    var statusItem: NSStatusItem!
    var preferencesWindow: NSWindow?
    var clipboardHistoryWindow: NSWindow?
    var popoverWindow: NSWindow?

    private override init() { super.init() }

    func setup() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            if let image = NSImage(systemSymbolName: "cursorarrow.rays", accessibilityDescription: "Leap") {
                button.image = image
            } else {
                button.title = "Leap"
            }
            button.action = #selector(togglePopover)
            button.target = self
        }
    }

    @objc func togglePopover() {
        if let window = popoverWindow, window.isVisible {
            closePopover()
        } else {
            showPopover()
        }
    }

    private func showPopover() {
        guard let button = statusItem.button else { return }

        // 计算位置
        let buttonFrame = button.window?.convertToScreen(button.frame) ?? .zero
        let windowWidth: CGFloat = 300
        let windowHeight: CGFloat = 500
        let arrowHeight: CGFloat = 10
        let arrowWidth: CGFloat = 20

        let windowX = buttonFrame.midX - windowWidth / 2
        let windowY = buttonFrame.minY - windowHeight - arrowHeight

        // 创建窗口
        let window = NSWindow(
            contentRect: NSRect(x: windowX, y: windowY, width: windowWidth, height: windowHeight + arrowHeight),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        window.level = .floating
        window.isReleasedWhenClosed = false

        // 创建内容视图
        let contentView = StatusMenuView(
            onClipboardHistory: { [weak self] in
                self?.closePopover()
                self?.openClipboardHistory()
            },
            onPreferences: { [weak self] in
                self?.closePopover()
                self?.openPreferences()
            },
            onQuit: {
                NSApp.terminate(nil)
            }
        )

        // 创建带箭头的容器视图
        let containerWidth = windowWidth
        let containerHeight = windowHeight + arrowHeight

        let containerHostingView = NSHostingView(rootView:
            PopoverContainer(
                arrowHeight: arrowHeight,
                arrowWidth: arrowWidth,
                content: contentView
            )
        )
        containerHostingView.frame = NSRect(x: 0, y: 0, width: containerWidth, height: containerHeight)

        window.contentView = containerHostingView
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        // 点击外部关闭
        NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.closePopover()
        }

        popoverWindow = window
    }

    func closePopover() {
        popoverWindow?.orderOut(nil)
        popoverWindow = nil
    }

    @objc func openPreferences() {
        if preferencesWindow == nil {
            let contentView = PreferencesView()
            preferencesWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 380, height: 200),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            preferencesWindow?.title = "偏好设置"
            preferencesWindow?.contentView = NSHostingView(rootView: contentView)
            preferencesWindow?.center()
            preferencesWindow?.isReleasedWhenClosed = false
        }
        preferencesWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc func openClipboardHistory() {
        if clipboardHistoryWindow == nil {
            let contentView = ClipboardHistoryView()
            clipboardHistoryWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 350, height: 450),
                styleMask: [.titled, .closable, .resizable],
                backing: .buffered,
                defer: false
            )
            clipboardHistoryWindow?.title = "剪切板历史"
            clipboardHistoryWindow?.contentView = NSHostingView(rootView: contentView)
            clipboardHistoryWindow?.center()
            clipboardHistoryWindow?.isReleasedWhenClosed = false
            clipboardHistoryWindow?.level = .floating
            clipboardHistoryWindow?.collectionBehavior = .fullScreenPrimary
        }
        NSApp.activate(ignoringOtherApps: true)
        clipboardHistoryWindow?.makeKeyAndOrderFront(nil)
        clipboardHistoryWindow?.orderFrontRegardless()
    }
}

struct PopoverContainer<Content: View>: View {
    let arrowHeight: CGFloat
    let arrowWidth: CGFloat
    let content: Content

    var body: some View {
        VStack(spacing: 0) {
            // 箭头
            ArrowShape(arrowWidth: arrowWidth, arrowHeight: arrowHeight)
                .fill(Color.white)
                .frame(width: arrowWidth, height: arrowHeight)
                .frame(maxWidth: .infinity, alignment: .center)

            // 内容
            content
                .background(Color.white)
                .cornerRadius(8)
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
        }
    }
}

struct ArrowShape: Shape {
    let arrowWidth: CGFloat
    let arrowHeight: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: arrowHeight))
        path.addLine(to: CGPoint(x: arrowWidth / 2, y: 0))
        path.addLine(to: CGPoint(x: arrowWidth, y: arrowHeight))
        path.closeSubpath()
        return path
    }
}
