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
    
    private var imagesDirectory: URL {
        let paths = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        let dir = paths[0].appendingPathComponent("LeapClipboardImages")
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }
    
    func saveImageData(_ data: Data, for id: UUID) {
        let url = imagesDirectory.appendingPathComponent(id.uuidString)
        try? data.write(to: url)
    }
    
    func loadImageData(for id: UUID) -> Data? {
        let url = imagesDirectory.appendingPathComponent(id.uuidString)
        return try? Data(contentsOf: url)
    }
    
    private func deleteImageData(for id: UUID) {
        let url = imagesDirectory.appendingPathComponent(id.uuidString)
        try? FileManager.default.removeItem(at: url)
    }
    
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
            var dataToSave: Data?
            var newId: UUID?
            
            if let string = first.string(forType: .string) {
                let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    newItem = ClipboardItem(type: .text, content: string)
                }
            } else if let image = NSImage(pasteboard: pasteboard), let tiffData = image.tiffRepresentation {
                let id = UUID()
                let finalData: Data
                if let bitmap = NSBitmapImageRep(data: tiffData), let pngData = bitmap.representation(using: .png, properties: [:]) {
                    finalData = pngData
                } else {
                    finalData = tiffData
                }
                
                newId = id
                dataToSave = finalData
                newItem = ClipboardItem(id: id, type: .image, content: "[图片 - \(finalData.count / 1024) KB]")
            }
            
            if let item = newItem {
                // 去重
                if let last = history.first, last.content == item.content && last.type == item.type {
                    return
                }
                
                if let data = dataToSave, let id = newId {
                    self.saveImageData(data, for: id)
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
            let itemsToRemove = history.dropFirst(savedHistoryLimit)
            for item in itemsToRemove {
                if item.type == .image {
                    deleteImageData(for: item.id)
                }
            }
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
        } else if item.type == .image {
            if let data = loadImageData(for: item.id), let image = NSImage(data: data) {
                pasteboard.writeObjects([image])
            } else if let content = item.content {
                // fallback to text if image data is lost
                pasteboard.setString(content, forType: .string)
            }
        }
        
        lastChangeCount = pasteboard.changeCount
    }
    
    func clearHistory() {
        history.removeAll()
        UserDefaults.standard.removeObject(forKey: historyKey)
        try? FileManager.default.removeItem(at: imagesDirectory)
    }
}
