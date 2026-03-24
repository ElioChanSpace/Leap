//
//  HotKeyManager.swift
//  Leap
//
//  Created by leon chen on 2026/3/19.
//

import Carbon
import CoreGraphics
import AppKit

class HotKeyManager {
    
    // 存储注册的热键引用（防止被释放）
    private var hotKeyRefs: [EventHotKeyRef] = []
    
    init() {
        setupEventHandler()
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name("ShortcutsDidUpdate"), object: nil, queue: .main) { [weak self] _ in
            self?.registerHotKeys()
        }
    }
    
    private func setupEventHandler() {
        var eventSpec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                      eventKind: UInt32(kEventHotKeyPressed))
        
        InstallEventHandler(
            GetApplicationEventTarget(),
            { (_, event, userData) -> OSStatus in
                guard let manager = userData.flatMap({
                    Unmanaged<HotKeyManager>.fromOpaque($0).takeUnretainedValue() as HotKeyManager?
                }) else {return noErr}
                manager.handleHotKey(event: event!)
                return noErr
            },
            1,
            &eventSpec,
            Unmanaged.passUnretained(self).toOpaque(),
            nil
        )
    }
    
    func registerHotKeys() {
        // 先移除所有旧热键
        for ref in hotKeyRefs {
            UnregisterEventHotKey(ref)
        }
        hotKeyRefs.removeAll()
        
        // 注册每个热键
        let shortcuts = ShortcutStore.shared.shortcuts
        for (index, shortcut) in shortcuts {
            let hotKeyID = EventHotKeyID(signature: OSType(0x434A5053), // "CJPS"
                                          id: UInt32(index))
            var hotKeyRef: EventHotKeyRef?
            
            RegisterEventHotKey(
                UInt32(shortcut.keyCode),
                shortcut.carbonModifiers,
                hotKeyID,
                GetApplicationEventTarget(),
                0,
                &hotKeyRef
            )
            
            if let ref = hotKeyRef {
                hotKeyRefs.append(ref)
            }
        }
    }
    
    private func handleHotKey(event: EventRef) {
        var hotKeyID = EventHotKeyID()
        GetEventParameter(event,
                          UInt32(kEventParamDirectObject),
                          UInt32(typeEventHotKeyID),
                          nil,
                          MemoryLayout<EventHotKeyID>.size,
                          nil,
                          &hotKeyID)
        
        let screenIndex = Int(hotKeyID.id)
        if screenIndex == 999 {
            MenuManager.shared.openClipboardHistory()
        } else {
            CursorManager.moveCursor(toScreenIndex: screenIndex)
        }
    }
}
