import Cocoa
import Combine
import SwiftUI

class ClipboardManager: ObservableObject {
    static let shared = ClipboardManager()
    
    @Published var history: [ClipboardItem] = []
    
    private let pasteboard = NSPasteboard.general
    private var lastChangeCount: Int = 0
    private var timer: Timer?
    
    @AppStorage("savedHistoryLimit") var savedHistoryLimit: Int = 50
    // Keep displayedHistoryLimit setting in AppStorage for UI usage, though manager doesn't strictly need it for storage limit
    // UI can read @AppStorage("displayedHistoryLimit")
    
    private let historyKey = "Leap_ClipboardHistory"
    
    // 忽略下一次pasteboard的变化，避免在应用内"复制"恢复时触发循环
    private var ignoreNextChange = false
    
    private init() {
        loadHistory()
        lastChangeCount = pasteboard.changeCount
    }
    
    func startListening() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkForChanges()
        }
    }
    
    private func checkForChanges() {
        guard pasteboard.changeCount != lastChangeCount else { return }
        lastChangeCount = pasteboard.changeCount
        
        if ignoreNextChange {
            ignoreNextChange = false
            return
        }
        
        if let items = pasteboard.pasteboardItems, let first = items.first {
            var newItem: ClipboardItem?
            
            if let string = first.string(forType: .string) {
                let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    newItem = ClipboardItem(type: .text, content: string)
                }
            } else if let image = NSImage(pasteboard: pasteboard), let tiffData = image.tiffRepresentation {
                // 对于图片，简单保存其大小信息而不保存实体以节省空间，或者保留简单的提示符
                newItem = ClipboardItem(type: .image, content: "[图片 - \(tiffData.count / 1024) KB]")
            }
            
            if let item = newItem {
                // 去重
                if let last = history.first, last.content == item.content && last.type == item.type {
                    return
                }
                
                DispatchQueue.main.async {
                    self.history.insert(item, at: 0)
                    self.truncateAndSaveHistory()
                }
            }
        }
    }
    
    func truncateAndSaveHistory() {
        if history.count > savedHistoryLimit {
            history = Array(history.prefix(savedHistoryLimit))
        }
        
        do {
            let data = try JSONEncoder().encode(history)
            UserDefaults.standard.set(data, forKey: historyKey)
        } catch {
            print("Failed to save clipboard history: \(error)")
        }
    }
    
    private func loadHistory() {
        if let data = UserDefaults.standard.data(forKey: historyKey) {
            do {
                history = try JSONDecoder().decode([ClipboardItem].self, from: data)
            } catch {
                print("Failed to load clipboard history: \(error)")
            }
        }
    }
    
    func copyToPasteboard(item: ClipboardItem) {
        ignoreNextChange = true
        pasteboard.clearContents()
        
        if item.type == .text, let content = item.content {
            pasteboard.setString(content, forType: .string)
        } else if item.type == .image, let content = item.content {
            // 目前图片没有被完整保存（只存了文本提示），只能将提示文本复制回剪切板作为补偿
            pasteboard.setString(content, forType: .string)
        }
        
        lastChangeCount = pasteboard.changeCount
    }
    
    func clearHistory() {
        history.removeAll()
        UserDefaults.standard.removeObject(forKey: historyKey)
    }
}
