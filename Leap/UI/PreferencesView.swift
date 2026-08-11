import SwiftUI
import Combine

struct PreferencesView: View {
    @StateObject private var store = ShortcutStore.shared
    @StateObject private var cursorManager = CursorManager.shared
    @State private var screenCount: Int = NSScreen.screens.count

    @AppStorage("savedHistoryLimit") private var savedHistoryLimit: Int = 50
    @AppStorage("displayedHistoryLimit") private var displayedHistoryLimit: Int = 20

    var body: some View {
        Form {
            Section("快捷键设置") {
                ForEach(0..<screenCount, id: \.self) { index in
                    HStack {
                        Text("跳到屏幕 \(index + 1)")
                        Spacer()

                        ShortcutItemView(index: index, shortcut: store.shortcuts[index])
                    }
                }
            }

            Section("剪切板设置") {
                Stepper("最大保存条数: \(savedHistoryLimit)", value: $savedHistoryLimit, in: 10...500, step: 10)
                    .onChange(of: savedHistoryLimit) { _ in
                        ClipboardManager.shared.truncateAndSaveHistory()
                    }
                Stepper("最大展示条数: \(displayedHistoryLimit)", value: $displayedHistoryLimit, in: 5...100, step: 5)
                Button("清空历史记录") {
                    ClipboardManager.shared.clearHistory()
                }
                .foregroundStyle(.red)

                HStack {
                    Text("打开剪切板历史快捷键")
                    Spacer()
                    ShortcutItemView(index: 999, shortcut: store.shortcuts[999])
                }
            }

            Section("鼠标跳转设置") {
                Toggle("启用窗口跟随", isOn: $cursorManager.enableWindowFollow)

                Button("清除记忆位置") {
                    cursorManager.clearRememberedPositions()
                }
                .foregroundStyle(.secondary)
            }

            Section("窗口管理") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("快捷键说明")
                        .font(.headline)

                    HStack {
                        Text("左半屏")
                        Spacer()
                        Text("⌘ + ←")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("右半屏")
                        Spacer()
                        Text("⌘ + →")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("上半屏")
                        Spacer()
                        Text("⌘ + ↑")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("下半屏")
                        Spacer()
                        Text("⌘ + ↓")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("全屏")
                        Spacer()
                        Text("⌘ + ↩")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 380, height: 500)
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didChangeScreenParametersNotification)) { _ in
            screenCount = NSScreen.screens.count
        }
        .onAppear {
            screenCount = NSScreen.screens.count
        }
    }
}

struct ShortcutItemView: View {
    let index: Int
    @State var shortcut: Shortcut?

    var body: some View {
        ZStack {
            ShortcutRecorder(shortcut: Binding(get: {
                shortcut
            }, set: { newShortcut in
                shortcut = newShortcut
                ShortcutStore.shared.save(shortcut: newShortcut, for: index)
            }))
            .frame(width: 80, height: 28)

            Text(shortcut?.stringRepresentation ?? "Click to record")
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(shortcut != nil ? .primary : .secondary)
                .allowsHitTesting(false)
        }
    }
}
