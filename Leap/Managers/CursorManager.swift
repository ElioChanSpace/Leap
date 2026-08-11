import AppKit
import SwiftUI
import Combine

class CursorManager: ObservableObject {
    static let shared = CursorManager()

    // 鼠标位置记忆
    @Published var rememberedPositions: [Int: CGPoint] = [:]

    // 设置
    @AppStorage("enableJumpAnimation") var enableJumpAnimation: Bool = true
    @AppStorage("enableWindowFollow") var enableWindowFollow: Bool = false

    // 动画层
    private var animationLayer: CAShapeLayer?

    // MARK: - 公开方法

    /// 移动鼠标到指定屏幕
    func moveCursor(toScreenIndex screenIndex: Int, followWindow: Bool = false) {
        let screens = NSScreen.screens
        guard screenIndex < screens.count else { return }

        let targetScreen = screens[screenIndex]
        let currentPoint = getCurrentMousePosition()

        // 优先使用记忆位置，否则使用窗口中心或屏幕中心
        let targetPoint: CGPoint
        if let remembered = rememberedPositions[screenIndex] {
            targetPoint = remembered
        } else {
            targetPoint = getTopWindowCenter(for: targetScreen) ?? getScreenCenter(for: targetScreen)
        }

        // 记录当前位置到源屏幕
        if let sourceScreen = NSScreen.screens.first(where: { $0.frame.contains(currentPoint) }) {
            let sourceIndex = NSScreen.screens.firstIndex(of: sourceScreen) ?? 0
            rememberedPositions[sourceIndex] = currentPoint
        }

        // 执行跳转
        if enableJumpAnimation {
            animateJump(from: currentPoint, to: targetPoint)
        } else {
            performJump(to: targetPoint)
        }

        // 窗口跟随
        if enableWindowFollow || followWindow {
            WindowManager.shared.moveActiveWindowToScreen(at: screenIndex)
        }
    }

    /// 清除记忆位置
    func clearRememberedPositions() {
        rememberedPositions.removeAll()
    }

    // MARK: - 跳转动画

    private func animateJump(from startPoint: CGPoint, to endPoint: CGPoint) {
        // 移除旧动画层
        animationLayer?.removeFromSuperlayer()

        // 创建路径
        let path = CGMutablePath()
        path.move(to: startPoint)

        // 计算控制点（弧线）
        let midX = (startPoint.x + endPoint.x) / 2
        let midY = (startPoint.y + endPoint.y) / 2
        let controlPoint = CGPoint(
            x: midX,
            y: min(startPoint.y, endPoint.y) - 50
        )

        path.addQuadCurve(to: endPoint, control: controlPoint)

        // 创建形状层
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = path
        shapeLayer.strokeColor = NSColor.controlAccentColor.cgColor
        shapeLayer.lineWidth = 2
        shapeLayer.fillColor = nil
        shapeLayer.lineDashPattern = [4, 4]

        // 添加到屏幕
        if let screen = NSScreen.main {
            let window = NSWindow(contentRect: screen.frame, styleMask: .borderless, backing: .buffered, defer: false)
            window.backgroundColor = .clear
            window.isOpaque = false
            window.hasShadow = false
            window.level = .screenSaver
            window.ignoresMouseEvents = true
            window.collectionBehavior = [.canJoinAllSpaces, .stationary]

            let contentView = NSView(frame: screen.frame)
            contentView.wantsLayer = true
            contentView.layer?.addSublayer(shapeLayer)
            window.contentView = contentView
            window.orderFront(nil)

            // 动画
            let animation = CABasicAnimation(keyPath: "strokeEnd")
            animation.fromValue = 0
            animation.toValue = 1
            animation.duration = 0.3
            animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

            shapeLayer.add(animation, forKey: "strokeEnd")

            // 动画结束后移动鼠标和移除窗口
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.performJump(to: endPoint)
                window.orderOut(nil)
                window.close()
            }
        } else {
            performJump(to: endPoint)
        }
    }

    private func performJump(to point: CGPoint) {
        CGWarpMouseCursorPosition(point)

        // 发送鼠标移动事件以便系统更新光标
        CGEvent(mouseEventSource: nil,
                mouseType: .mouseMoved,
                mouseCursorPosition: point,
                mouseButton: .left)?.post(tap: .cghidEventTap)
    }

    // MARK: - 辅助方法

    private func getCurrentMousePosition() -> CGPoint {
        return NSEvent.mouseLocation
    }

    private func getScreenCenter(for screen: NSScreen) -> CGPoint {
        let screenFrame = screen.frame
        let mainScreenHeight = NSScreen.screens[0].frame.height

        let centerX = screenFrame.midX
        let centerY = mainScreenHeight - screenFrame.midY

        return CGPoint(x: centerX, y: centerY)
    }

    private func cgBounds(for screen: NSScreen) -> CGRect {
        if let screenNumber = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber {
            return CGDisplayBounds(screenNumber.uint32Value)
        }

        let mainScreenHeight = NSScreen.screens[0].frame.height
        var frame = screen.frame
        frame.origin.y = mainScreenHeight - frame.maxY
        return frame
    }

    private func getTopWindowCenter(for screen: NSScreen) -> CGPoint? {
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
