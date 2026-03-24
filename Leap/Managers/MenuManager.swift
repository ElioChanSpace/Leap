import Cocoa
import SwiftUI

class MenuManager: NSObject {
    static let shared = MenuManager()
    
    var statusItem: NSStatusItem!
    var preferencesWindow: NSWindow?
    var clipboardHistoryWindow: NSWindow?
    
    private override init() { super.init() }
    
    func setup() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            if let image = NSImage(systemSymbolName: "cursorarrow.rays", accessibilityDescription: "Leap") {
                button.image = image
            } else {
                button.title = "Leap"
            }
        }
        
        let menu = NSMenu()
        let clipboardItem = NSMenuItem(title: "剪切板历史...", action: #selector(openClipboardHistory), keyEquivalent: "h")
        clipboardItem.target = self
        menu.addItem(clipboardItem)
        menu.addItem(NSMenuItem.separator())
        
        let prefItem = NSMenuItem(title: "偏好设置...", action: #selector(openPreferences), keyEquivalent: ",")
        prefItem.target = self
        menu.addItem(prefItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "退出",
                                action: #selector(NSApplication.terminate(_:)),
                                keyEquivalent: "q"))
        statusItem.menu = menu
        
        openPreferences()
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
            clipboardHistoryWindow?.level = .floating // 确保在其他窗口之上
        }
        NSApp.activate(ignoringOtherApps: true)
        clipboardHistoryWindow?.makeKeyAndOrderFront(nil)
        clipboardHistoryWindow?.orderFrontRegardless()
    }
}
