import SwiftUI

struct ClipboardHistoryView: View {
    @StateObject private var manager = ClipboardManager.shared
    @AppStorage("displayedHistoryLimit") private var displayedHistoryLimit: Int = 20
    
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
                        }) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(item.content ?? "未知内容")
                                    .font(.system(.body, design: .rounded))
                                    .lineLimit(3)
                                    .truncationMode(.tail)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
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
}
