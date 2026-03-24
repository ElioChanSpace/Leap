import SwiftUI
import Combine

struct PreferencesView: View {
    @StateObject private var store = ShortcutStore.shared
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
                        
                        // Custom shortcut recorder implementation
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
                .foregroundColor(.red)
                
                HStack {
                    Text("打开剪切板历史快捷键")
                    Spacer()
                    ShortcutItemView(index: 999, shortcut: store.shortcuts[999])
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 380, height: 320)
        .padding()
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
