import SwiftUI

struct ClipboardHistoryView: View {
    @StateObject private var manager = ClipboardManager.shared
    @AppStorage("displayedHistoryLimit") private var displayedHistoryLimit: Int = 20
    
    @State private var hoveredImageId: UUID?
    
    var displayedHistory: [ClipboardItem] {
        Array(manager.history.prefix(displayedHistoryLimit))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Text("剪切板历史")
                .font(.headline)
                .padding(.top, 16)
                .padding(.bottom, 8)
            
            Divider()
            
            if displayedHistory.isEmpty {
                Text("暂无记录")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(displayedHistory) { item in
                        Button(action: {
                            copyItem(item)
                        }) {
                            VStack(alignment: .leading, spacing: 6) {
                                if item.type == .image, let data = manager.loadImageData(for: item.id), let nsImage = NSImage(data: data) {
                                    Button(action: {
                                        PreviewWindowManager.shared.showPreview(for: nsImage)
                                    }) {
                                        Image(nsImage: nsImage)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(maxHeight: 100)
                                            .cornerRadius(4)
                                            .overlay(
                                                Group {
                                                    if hoveredImageId == item.id {
                                                        Color.black.opacity(0.3)
                                                            .cornerRadius(4)
                                                        Image(systemName: "plus.magnifyingglass")
                                                            .font(.title)
                                                            .foregroundColor(.white)
                                                    }
                                                }
                                            )
                                    }
                                    .buttonStyle(.plain)
                                    .onHover { isHovered in
                                        if isHovered {
                                            hoveredImageId = item.id
                                        } else {
                                            if hoveredImageId == item.id {
                                                hoveredImageId = nil
                                            }
                                        }
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                } else {
                                    Text(item.content ?? "未知内容")
                                        .font(.system(.body, design: .rounded))
                                        .lineLimit(3)
                                        .truncationMode(.tail)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                
                                HStack {
                                    if item.type == .image {
                                        Image(systemName: "photo")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    } else {
                                        Image(systemName: "doc.text")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Text(item.timestamp, style: .time)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 6)
                            .padding(.horizontal, 4)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        
                        Divider()
                    }
                }
                .listStyle(.sidebar)
                .scrollContentBackground(.hidden)
            }
        }
        .frame(width: 350, height: 450)
    }
    
    private func copyItem(_ item: ClipboardItem) {
        manager.copyToPasteboard(item: item)
        if let window = NSApplication.shared.windows.first(where: { $0.title == "剪切板历史" }) {
            window.close()
        }
        
        // 隐藏当前应用，将焦点交还给前一个应用
        NSApp.hide(nil)
        
        // 稍微延迟以确保焦点已经回到目标应用，然后模拟 Cmd+V
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let source = CGEventSource(stateID: .hidSystemState)
            let vKeyDown = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: true)
            let vKeyUp = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: false)
            
            vKeyDown?.flags = .maskCommand
            vKeyUp?.flags = .maskCommand
            
            vKeyDown?.post(tap: .cghidEventTap)
            vKeyUp?.post(tap: .cghidEventTap)
        }
    }
}

class PreviewWindowManager {
    static let shared = PreviewWindowManager()
    private var windows: [NSWindow] = []
    
    func showPreview(for image: NSImage) {
        var windowWidth = image.size.width
        var windowHeight = image.size.height
        
        if let screenFrame = NSScreen.main?.visibleFrame {
            let maxWidth = screenFrame.width * 0.8
            let maxHeight = screenFrame.height * 0.8
            
            if windowWidth > maxWidth || windowHeight > maxHeight {
                let ratio = min(maxWidth / windowWidth, maxHeight / windowHeight)
                windowWidth *= ratio
                windowHeight *= ratio
            }
        }
        
        windowWidth = max(windowWidth, 200)
        windowHeight = max(windowHeight, 200)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: windowWidth, height: windowHeight),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = "图片预览"
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.collectionBehavior = .fullScreenPrimary
        
        window.center()
        window.isReleasedWhenClosed = false
        window.level = .popUpMenu
        
        let imageView = Image(nsImage: image)
            .resizable()
            .scaledToFit()
            
        window.contentView = NSHostingView(rootView: imageView)
        
        NotificationCenter.default.addObserver(forName: NSWindow.willCloseNotification, object: window, queue: .main) { [weak self] _ in
            self?.windows.removeAll { $0 === window }
        }
        
        windows.append(window)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
