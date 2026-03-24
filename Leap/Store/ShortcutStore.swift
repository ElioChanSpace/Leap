import Foundation
import Combine
import Carbon

class ShortcutStore: ObservableObject {
    @Published var shortcuts: [Int: Shortcut] = [:]
    
    static let shared = ShortcutStore()
    
    private init() {
        load()
        if shortcuts.isEmpty {
            let defaults: [Int: Shortcut] = [
                0: Shortcut(keyCode: 18, carbonModifiers: UInt32(optionKey), stringRepresentation: "⌥1"),
                1: Shortcut(keyCode: 19, carbonModifiers: UInt32(optionKey), stringRepresentation: "⌥2"),
                2: Shortcut(keyCode: 20, carbonModifiers: UInt32(optionKey), stringRepresentation: "⌥3"),
                3: Shortcut(keyCode: 21, carbonModifiers: UInt32(optionKey), stringRepresentation: "⌥4")
            ]
            self.shortcuts = defaults
            
            // Save to UserDefaults silently without posting notification
            for (index, shortcut) in defaults {
                if let data = try? JSONEncoder().encode(shortcut),
                   let string = String(data: data, encoding: .utf8) {
                    UserDefaults.standard.set(string, forKey: "shortcut_\(index)")
                }
            }
        }
        
        // Ensure clipboard history shortcut has a default value if not set
        if shortcuts[999] == nil {
            let defaultClipboard = Shortcut(keyCode: 9, carbonModifiers: UInt32(optionKey), stringRepresentation: "⌥V")
            shortcuts[999] = defaultClipboard
            if let data = try? JSONEncoder().encode(defaultClipboard),
               let string = String(data: data, encoding: .utf8) {
                UserDefaults.standard.set(string, forKey: "shortcut_999")
            }
        }
    }
    
    func load() {
        var newShortcuts: [Int: Shortcut] = [:]
        for i in [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 999] { // Support screens and 999 for clipboard
            if let string = UserDefaults.standard.string(forKey: "shortcut_\(i)"),
               let data = string.data(using: .utf8),
               let shortcut = try? JSONDecoder().decode(Shortcut.self, from: data) {
                newShortcuts[i] = shortcut
            }
        }
        self.shortcuts = newShortcuts
    }
    
    func save(shortcut: Shortcut?, for screenIndex: Int) {
        shortcuts[screenIndex] = shortcut
        if let shortcut = shortcut,
           let data = try? JSONEncoder().encode(shortcut),
           let string = String(data: data, encoding: .utf8) {
            UserDefaults.standard.set(string, forKey: "shortcut_\(screenIndex)")
        } else {
            UserDefaults.standard.removeObject(forKey: "shortcut_\(screenIndex)")
        }
        NotificationCenter.default.post(name: NSNotification.Name("ShortcutsDidUpdate"), object: nil)
    }
}
