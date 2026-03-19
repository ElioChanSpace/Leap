import SwiftUI
import Combine

struct PreferencesView: View {
    @StateObject private var store = ShortcutStore.shared
    @State private var screenCount: Int = NSScreen.screens.count
    
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
