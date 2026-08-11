import Cocoa
import SwiftUI

class MenuManager: NSObject {
    static let shared = MenuManager()

    var statusItem: NSStatusItem!
    var preferencesWindow: NSWindow?
    var clipboardHistoryWindow: NSWindow?
    var popover: NSPopover?

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

        setupPopover()
    }

    private func setupPopover() {
        let popover = NSPopover()
        popover.contentSize = NSSize(width: 300, height: 500)
        popover.behavior = .transient
        popover.animates = true
        popover.appearance = NSAppearance(named: .aqua)
        popover.contentViewController = NSHostingController(rootView: StatusMenuView(
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
        ))
        self.popover = popover
    }

    @objc func togglePopover() {
        guard let button = statusItem.button else { return }

        if let popover = popover, popover.isShown {
            popover.performClose(nil)
        } else {
            popover?.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            // 确保 popover 窗口在最前面
            popover?.contentViewController?.view.window?.makeKey()
        }
    }

    func closePopover() {
        popover?.performClose(nil)
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
