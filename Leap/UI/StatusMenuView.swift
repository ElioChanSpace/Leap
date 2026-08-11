import SwiftUI

struct StatusMenuView: View {
    @StateObject private var monitor = SystemMonitor()
    @StateObject private var clipboardManager = ClipboardManager.shared

    var onClipboardHistory: () -> Void
    var onPreferences: () -> Void
    var onQuit: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // 系统状态卡片
            SystemStatsCard(monitor: monitor)
                .padding(16)

            Divider()

            // 剪切板历史预览
            clipboardSection

            Divider()

            // 操作按钮
            VStack(spacing: 0) {
                MenuButton(
                    icon: "gearshape",
                    title: "偏好设置",
                    shortcut: "⌘,"
                ) {
                    onPreferences()
                }

                MenuButton(
                    icon: "arrow.right.square",
                    title: "退出 Leap",
                    shortcut: "⌘Q"
                ) {
                    onQuit()
                }
            }
            .padding(.vertical, 8)
        }
        .frame(width: 300)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            monitor.startMonitoring()
        }
        .onDisappear {
            monitor.stopMonitoring()
        }
    }

    private var clipboardSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "doc.on.clipboard")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)

                Text("剪切板历史")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)

                Spacer()

                Text("\(clipboardManager.history.count) 项")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }

            if clipboardManager.history.isEmpty {
                HStack {
                    Spacer()
                    Text("暂无记录")
                        .font(.system(size: 12))
                        .foregroundStyle(.tertiary)
                    Spacer()
                }
                .padding(.vertical, 8)
            } else {
                ForEach(clipboardManager.history.prefix(3)) { item in
                    clipboardItemRow(item)
                }
            }

            HStack(spacing: 3) {
                Text("查看全部")
                    .font(.system(size: 11, weight: .medium))

                Image(systemName: "chevron.right")
                    .font(.system(size: 9, weight: .semibold))
            }
            .foregroundStyle(.blue)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.top, 6)
            .contentShape(Rectangle())
            .onTapGesture {
                onClipboardHistory()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func clipboardItemRow(_ item: ClipboardItem) -> some View {
        HStack(spacing: 8) {
            Image(systemName: item.type == .image ? "photo" : "doc.text")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
                .frame(width: 16)

            Text(item.content ?? "图片")
                .font(.system(size: 11))
                .lineLimit(1)
                .truncationMode(.tail)

            Spacer()

            Text(item.timestamp, style: .relative)
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}

struct MenuButton: View {
    let icon: String
    let title: String
    let shortcut: String
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .frame(width: 20)

                Text(title)
                    .font(.system(size: 13))

                Spacer()

                Text(shortcut)
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .background(isHovered ? Color.accentColor.opacity(0.1) : Color.clear)
            .cornerRadius(4)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
        .padding(.horizontal, 8)
    }
}

#Preview {
    StatusMenuView(
        onClipboardHistory: {},
        onPreferences: {},
        onQuit: {}
    )
}
