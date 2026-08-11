import SwiftUI

struct ClipboardHistoryView: View {
    @StateObject private var manager = ClipboardManager.shared
    @AppStorage("displayedHistoryLimit") private var displayedHistoryLimit: Int = 20

    @State private var hoveredImageId: UUID?
    @State private var selectedIndex: Int?

    var displayedHistory: [ClipboardItem] {
        Array(manager.history.prefix(displayedHistoryLimit))
    }

    var body: some View {
        VStack(spacing: 0) {
            if displayedHistory.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "clipboard")
                        .font(.system(size: 48))
                        .foregroundStyle(.tertiary)
                    Text("暂无记录")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 1) {
                            ForEach(Array(displayedHistory.enumerated()), id: \.element.id) { index, item in
                                ClipboardItemRow(
                                    item: item,
                                    isSelected: selectedIndex == index,
                                    isHovered: hoveredImageId == item.id,
                                    onPreviewImage: { image in
                                        PreviewWindowManager.shared.showPreview(for: image)
                                    }
                                )
                                .onTapGesture {
                                    copyItem(item)
                                }
                                .onHover { isHovered in
                                    if isHovered {
                                        hoveredImageId = item.id
                                    } else {
                                        if hoveredImageId == item.id {
                                            hoveredImageId = nil
                                        }
                                    }
                                }
                                .id(index)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .background(Color(NSColor.controlBackgroundColor))
                    .onChange(of: selectedIndex) { newIndex in
                        if let index = newIndex {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                proxy.scrollTo(index, anchor: .center)
                            }
                        }
                    }
                }
            }
        }
        .frame(width: 350, height: 450)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                handleKeyPress(event)
            }
        }
    }

    private func handleKeyPress(_ event: NSEvent) -> NSEvent? {
        guard !displayedHistory.isEmpty else { return event }

        switch event.keyCode {
        case 126: // 上箭头
            if let index = selectedIndex {
                selectedIndex = max(0, index - 1)
            } else {
                selectedIndex = 0
            }
            return nil
        case 125: // 下箭头
            if let index = selectedIndex {
                selectedIndex = min(displayedHistory.count - 1, index + 1)
            } else {
                selectedIndex = 0
            }
            return nil
        case 36: // 回车
            if let index = selectedIndex, index < displayedHistory.count {
                copyItem(displayedHistory[index])
            }
            return nil
        default:
            return event
        }
    }

    private func copyItem(_ item: ClipboardItem) {
        manager.copyToPasteboard(item: item)
        if let window = NSApplication.shared.windows.first(where: { $0.title == "剪切板历史" }) {
            window.close()
        }

        NSApp.hide(nil)

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

struct ClipboardItemRow: View {
    let item: ClipboardItem
    let isSelected: Bool
    let isHovered: Bool
    let onPreviewImage: ((NSImage) -> Void)?

    @StateObject private var manager = ClipboardManager.shared

    var body: some View {
        HStack(spacing: 12) {
            // 图标或图片缩略图
            if item.type == .image, let data = manager.loadImageData(for: item.id), let nsImage = NSImage(data: data) {
                Image(nsImage: nsImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .cornerRadius(4)
                    .onTapGesture {
                        onPreviewImage?(nsImage)
                    }
            } else {
                Image(systemName: item.type == .image ? "photo" : "doc.text")
                    .font(.system(size: 14))
                    .foregroundStyle(isSelected ? .white : .secondary)
                    .frame(width: 20)
            }

            // 内容
            VStack(alignment: .leading, spacing: 4) {
                if item.type == .image {
                    Text("图片")
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(isSelected ? .white : .primary)
                } else {
                    Text(item.content ?? "未知内容")
                        .font(.system(.body, design: .rounded))
                        .lineLimit(2)
                        .truncationMode(.tail)
                        .foregroundStyle(isSelected ? .white : .primary)
                }

                Text(item.timestamp, style: .time)
                    .font(.caption)
                    .foregroundStyle(isSelected ? .white.opacity(0.8) : .secondary)
            }

            Spacer()

            // 复制图标
            Image(systemName: "doc.on.doc")
                .font(.caption)
                .foregroundStyle(isSelected ? .white.opacity(0.6) : .gray.opacity(0.3))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? Color.accentColor : (isHovered ? Color(NSColor.controlAccentColor).opacity(0.1) : Color.clear))
        )
        .padding(.horizontal, 8)
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
