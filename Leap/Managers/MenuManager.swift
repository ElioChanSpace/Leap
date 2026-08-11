import Cocoa
import SwiftUI

class MenuManager: NSObject {
    static let shared = MenuManager()

    var statusItem: NSStatusItem!
    var preferencesWindow: NSWindow?
    var clipboardHistoryWindow: NSWindow?
    var popoverWindow: NSWindow?
    private var globalMonitor: Any?

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

        // 移除旧的全局事件监听器
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
            globalMonitor = nil
        }

        // 点击外部关闭
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.closePopover()
        }

        popoverWindow = window
    }

    func closePopover() {
        popoverWindow?.orderOut(nil)
        popoverWindow = nil

        // 移除全局事件监听器
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
            globalMonitor = nil
        }
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
            // 箭头 - 带阴影效果
            ArrowShape(arrowWidth: arrowWidth, arrowHeight: arrowHeight)
                .fill(Color.white)
                .frame(width: arrowWidth, height: arrowHeight)
                .frame(maxWidth: .infinity, alignment: .center)
                .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 2)

            // 内容
            content
                .background(Color.white)
                .cornerRadius(8)
                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
        }
    }
}

struct ArrowShape: Shape {
    let arrowWidth: CGFloat
    let arrowHeight: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()

        // 使用贝塞尔曲线创建更圆润的箭头
        let startX: CGFloat = 0
        let endX: CGFloat = arrowWidth
        let midX: CGFloat = arrowWidth / 2
        let topY: CGFloat = 0
        let bottomY: CGFloat = arrowHeight
        let curveOffset: CGFloat = arrowHeight * 0.4

        path.move(to: CGPoint(x: startX, y: bottomY))

        // 左侧曲线
        path.addQuadCurve(
            to: CGPoint(x: midX, y: topY),
            control: CGPoint(x: midX - curveOffset, y: bottomY - curveOffset)
        )

        // 右侧曲线
        path.addQuadCurve(
            to: CGPoint(x: endX, y: bottomY),
            control: CGPoint(x: midX + curveOffset, y: bottomY - curveOffset)
        )

        path.closeSubpath()
        return path
    }
}
