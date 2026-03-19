import AppKit

struct CursorManager {
    static func moveCursor(toScreenIndex screenIndex: Int) {
        let screens = NSScreen.screens
        guard screenIndex < screens.count else { return }
        
        let targetScreen = screens[screenIndex]
        
        // NSScreen 坐标系原点在左下角，CGWarpMouseCursorPosition 原点在左上角
        let screenFrame = targetScreen.frame
        let mainScreenHeight = NSScreen.screens[0].frame.height
        
        let centerX = screenFrame.midX
        let centerY = mainScreenHeight - screenFrame.midY
        
        let point = CGPoint(x: centerX, y: centerY)
        CGWarpMouseCursorPosition(point)
        
        // 发送鼠标移动事件以便系统更新光标
        CGEvent(mouseEventSource: nil,
                mouseType: .mouseMoved,
                mouseCursorPosition: point,
                mouseButton: .left)?.post(tap: .cghidEventTap)
    }
}
