import AppKit

struct CursorManager {
    static func moveCursor(toScreenIndex screenIndex: Int) {
        let screens = NSScreen.screens
        guard screenIndex < screens.count else { return }
        
        let targetScreen = screens[screenIndex]
        
        let point = getTopWindowCenter(for: targetScreen) ?? getScreenCenter(for: targetScreen)
        
        CGWarpMouseCursorPosition(point)
        
        // 发送鼠标移动事件以便系统更新光标
        CGEvent(mouseEventSource: nil,
                mouseType: .mouseMoved,
                mouseCursorPosition: point,
                mouseButton: .left)?.post(tap: .cghidEventTap)
    }
    
    private static func getScreenCenter(for screen: NSScreen) -> CGPoint {
        let screenFrame = screen.frame
        let mainScreenHeight = NSScreen.screens[0].frame.height
        
        let centerX = screenFrame.midX
        let centerY = mainScreenHeight - screenFrame.midY
        
        return CGPoint(x: centerX, y: centerY)
    }
    
    private static func cgBounds(for screen: NSScreen) -> CGRect {
        if let screenNumber = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber {
            return CGDisplayBounds(screenNumber.uint32Value)
        }
        
        let mainScreenHeight = NSScreen.screens[0].frame.height
        var frame = screen.frame
        frame.origin.y = mainScreenHeight - frame.maxY
        return frame
    }
    
    private static func getTopWindowCenter(for screen: NSScreen) -> CGPoint? {
        let screenCGBounds = cgBounds(for: screen)
        
        guard let windowInfoList = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] else {
            return nil
        }
        
        for info in windowInfoList {
            guard let layer = info[kCGWindowLayer as String] as? Int, layer == 0 else { continue }
            
            guard let boundsDict = info[kCGWindowBounds as String] as? [String: Any],
                  let bounds = CGRect(dictionaryRepresentation: boundsDict as CFDictionary) else { continue }
            
            // 过滤掉太小的窗口（往往不是主窗口）
            guard bounds.width > 50 && bounds.height > 50 else { continue }
            
            if bounds.intersects(screenCGBounds) {
                let intersection = bounds.intersection(screenCGBounds)
                let area = intersection.width * intersection.height
                let windowArea = bounds.width * bounds.height
                
                // 窗口的大部分在目标屏幕上
                if area > windowArea * 0.5 {
                    if let pid = info[kCGWindowOwnerPID as String] as? pid_t {
                        if let app = NSRunningApplication(processIdentifier: pid) {
                            app.activate(options: .activateIgnoringOtherApps)
                        }
                    }
                    return CGPoint(x: bounds.midX, y: bounds.midY)
                }
            }
        }
        
        return nil
    }
}
