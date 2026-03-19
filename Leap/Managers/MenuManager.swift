import Cocoa
import SwiftUI

class MenuManager: NSObject {
    static let shared = MenuManager()
    
    var statusItem: NSStatusItem!
    var preferencesWindow: NSWindow?
    
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
}
