//
//  AppDelegate.swift
//  Leap
//
//  Created by leon chen on 2026/3/19.
//
import Cocoa
import SwiftUI
import Carbon

@main
struct LeapApp {
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    
    var hotKeyManager: HotKeyManager!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        
        // 启动剪切板记录
        ClipboardManager.shared.startListening()
        
        // 配置菜单与偏好设置窗口
        MenuManager.shared.setup()
        
        // 启动热键管理器
        hotKeyManager = HotKeyManager()
        hotKeyManager.registerHotKeys()
    }
}
