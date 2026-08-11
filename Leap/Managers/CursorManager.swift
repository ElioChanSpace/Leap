import AppKit
import SwiftUI
import Combine

class CursorManager: ObservableObject {
    static let shared = CursorManager()

    // 鼠标位置记忆
    @Published var rememberedPositions: [Int: CGPoint] = [:]

    @AppStorage("enableWindowFollow") var enableWindowFollow: Bool = false

    // MARK: - 公开方法

    /// 移动鼠标到指定屏幕
    func moveCursor(toScreenIndex screenIndex: Int, followWindow: Bool = false) {
        let screens = NSScreen.screens
        guard !screens.isEmpty, screenIndex < screens.count else { return }

        let targetScreen = screens[screenIndex]
        let currentPoint = getCurrentMousePosition()

        // 优先使用记忆位置，否则使用屏幕中心
        let targetPoint: CGPoint
        if let remembered = rememberedPositions[screenIndex] {
            targetPoint = remembered
        } else {
            targetPoint = getScreenCenter(for: targetScreen)
        }

        // 记录当前位置到源屏幕
        if let sourceScreen = screens.first(where: { $0.frame.contains(currentPoint) }),
           let sourceIndex = screens.firstIndex(of: sourceScreen) {
            rememberedPositions[sourceIndex] = currentPoint
        }

        // 执行跳转
        performJump(to: targetPoint)

        // 窗口跟随
        if enableWindowFollow || followWindow {
            WindowManager.shared.moveActiveWindowToScreen(at: screenIndex)
        }
    }

    /// 清除记忆位置
    func clearRememberedPositions() {
        rememberedPositions.removeAll()
    }

    // MARK: - 跳转

    private func performJump(to point: CGPoint) {
        guard point.x.isFinite, point.y.isFinite else { return }
        CGWarpMouseCursorPosition(point)
    }

    // MARK: - 辅助方法

    private func getCurrentMousePosition() -> CGPoint {
        return NSEvent.mouseLocation
    }

    private func getScreenCenter(for screen: NSScreen) -> CGPoint {
        let screenFrame = screen.frame
        let mainScreenHeight = NSScreen.screens.first?.frame.height ?? screenFrame.height

        let centerX = screenFrame.midX
        let centerY = mainScreenHeight - screenFrame.midY

        return CGPoint(x: centerX, y: centerY)
    }
}
