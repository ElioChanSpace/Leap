import Cocoa
import ApplicationServices

class WindowManager {
    static let shared = WindowManager()

    // 窗口吸附阈值（像素）
    private let snapThreshold: CGFloat = 10

    // MARK: - 窗口布局预设

    enum WindowLayout {
        case leftHalf
        case rightHalf
        case topHalf
        case bottomHalf
        case topLeft
        case topRight
        case bottomLeft
        case bottomRight
        case fullScreen
        case center
    }

    /// 将当前活动窗口移动到指定布局
    func moveActiveWindow(to layout: WindowLayout) {
        guard let window = getActiveWindow(),
              let screen = window.screen ?? NSScreen.main else { return }

        let screenFrame = screen.visibleFrame
        let newFrame = calculateFrame(for: layout, in: screenFrame)

        moveWindow(window, to: newFrame)
    }

    /// 将当前活动窗口移动到指定屏幕
    func moveActiveWindowToScreen(at index: Int) {
        guard let window = getActiveWindow(),
              index < NSScreen.screens.count else { return }

        let targetScreen = NSScreen.screens[index]
        let currentScreen = window.screen ?? NSScreen.main

        // 计算窗口在目标屏幕上的相对位置
        let currentFrame = window.frame
        let targetFrame = targetScreen.visibleFrame

        let relativeX = (currentFrame.origin.x - (currentScreen?.frame.origin.x ?? 0)) / (currentScreen?.frame.width ?? 1)
        let relativeY = (currentFrame.origin.y - (currentScreen?.frame.origin.y ?? 0)) / (currentScreen?.frame.height ?? 1)

        let newX = targetFrame.origin.x + relativeX * targetFrame.width
        let newY = targetFrame.origin.y + relativeY * targetFrame.height

        // 保持窗口大小，但确保不超出目标屏幕
        let newWidth = min(currentFrame.width, targetFrame.width)
        let newHeight = min(currentFrame.height, targetFrame.height)

        let newFrame = NSRect(
            x: newX,
            y: newY,
            width: newWidth,
            height: newHeight
        )

        moveWindow(window, to: newFrame)
    }

    // MARK: - 窗口吸附

    /// 检查窗口是否应该吸附到屏幕边缘
    func checkForSnap(_ window: NSWindow) {
        guard let screen = window.screen ?? NSScreen.main else { return }

        let windowFrame = window.frame
        let screenFrame = screen.visibleFrame

        var newFrame = windowFrame

        // 左边缘吸附
        if abs(windowFrame.minX - screenFrame.minX) < snapThreshold {
            newFrame.origin.x = screenFrame.minX
        }

        // 右边缘吸附
        if abs(windowFrame.maxX - screenFrame.maxX) < snapThreshold {
            newFrame.origin.x = screenFrame.maxX - windowFrame.width
        }

        // 上边缘吸附
        if abs(windowFrame.maxY - screenFrame.maxY) < snapThreshold {
            newFrame.origin.y = screenFrame.maxY - windowFrame.height
        }

        // 下边缘吸附
        if abs(windowFrame.minY - screenFrame.minY) < snapThreshold {
            newFrame.origin.y = screenFrame.minY
        }

        if newFrame != windowFrame {
            moveWindow(window, to: newFrame)
        }
    }

    // MARK: - 辅助方法

    private func getActiveWindow() -> NSWindow? {
        // 获取当前活动应用程序的窗口
        guard let app = NSWorkspace.shared.frontmostApplication else { return nil }

        // 使用 Accessibility API 获取窗口
        let appRef = AXUIElementCreateApplication(app.processIdentifier)
        var windowRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(appRef, kAXFocusedWindowAttribute as CFString, &windowRef)

        guard result == .success, let window = windowRef else {
            // 降级方案：返回应用程序的第一个窗口
            return NSApp.windows.first
        }

        // 获取窗口位置和大小
        var position: CFTypeRef?
        var size: CFTypeRef?

        AXUIElementCopyAttributeValue(window as! AXUIElement, kAXPositionAttribute as CFString, &position)
        AXUIElementCopyAttributeValue(window as! AXUIElement, kAXSizeAttribute as CFString, &size)

        guard let positionValue = position, let sizeValue = size else { return nil }

        var point = CGPoint.zero
        var windowSize = CGSize.zero

        AXValueGetValue(positionValue as! AXValue, .cgPoint, &point)
        AXValueGetValue(sizeValue as! AXValue, .cgSize, &windowSize)

        // 查找匹配的 NSWindow
        for window in NSApp.windows {
            let windowFrame = window.frame
            if abs(windowFrame.origin.x - point.x) < 1 &&
               abs(windowFrame.origin.y - point.y) < 1 &&
               abs(windowFrame.width - windowSize.width) < 1 &&
               abs(windowFrame.height - windowSize.height) < 1 {
                return window
            }
        }

        return nil
    }

    private func calculateFrame(for layout: WindowLayout, in screenFrame: NSRect) -> NSRect {
        let width = screenFrame.width
        let height = screenFrame.height
        let x = screenFrame.origin.x
        let y = screenFrame.origin.y

        switch layout {
        case .leftHalf:
            return NSRect(x: x, y: y, width: width / 2, height: height)

        case .rightHalf:
            return NSRect(x: x + width / 2, y: y, width: width / 2, height: height)

        case .topHalf:
            return NSRect(x: x, y: y + height / 2, width: width, height: height / 2)

        case .bottomHalf:
            return NSRect(x: x, y: y, width: width, height: height / 2)

        case .topLeft:
            return NSRect(x: x, y: y + height / 2, width: width / 2, height: height / 2)

        case .topRight:
            return NSRect(x: x + width / 2, y: y + height / 2, width: width / 2, height: height / 2)

        case .bottomLeft:
            return NSRect(x: x, y: y, width: width / 2, height: height / 2)

        case .bottomRight:
            return NSRect(x: x + width / 2, y: y, width: width / 2, height: height / 2)

        case .fullScreen:
            return screenFrame

        case .center:
            let windowWidth = width * 0.8
            let windowHeight = height * 0.8
            return NSRect(
                x: x + (width - windowWidth) / 2,
                y: y + (height - windowHeight) / 2,
                width: windowWidth,
                height: windowHeight
            )
        }
    }

    private func moveWindow(_ window: NSWindow, to frame: NSRect) {
        // 使用 Accessibility API 移动窗口
        guard let app = NSWorkspace.shared.frontmostApplication else { return }

        let appRef = AXUIElementCreateApplication(app.processIdentifier)
        var windowRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(appRef, kAXFocusedWindowAttribute as CFString, &windowRef)

        guard result == .success, let windowElement = windowRef else {
            // 降级方案：直接移动 NSWindow
            window.setFrame(frame, display: true, animate: true)
            return
        }

        // 设置窗口位置
        var point = frame.origin
        let positionValue = AXValueCreate(.cgPoint, &point)
        AXUIElementSetAttributeValue(windowElement as! AXUIElement, kAXPositionAttribute as CFString, positionValue!)

        // 设置窗口大小
        var size = frame.size
        let sizeValue = AXValueCreate(.cgSize, &size)
        AXUIElementSetAttributeValue(windowElement as! AXUIElement, kAXSizeAttribute as CFString, sizeValue!)
    }
}
