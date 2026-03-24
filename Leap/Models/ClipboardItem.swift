import Foundation

enum ClipboardItemType: String, Codable {
    case text
    case image
    case other
}

struct ClipboardItem: Identifiable, Codable {
    let id: UUID
    let type: ClipboardItemType
    let content: String?
    let timestamp: Date
    
    init(id: UUID = UUID(), type: ClipboardItemType, content: String? = nil, timestamp: Date = Date()) {
        self.id = id
        self.type = type
        self.content = content
        self.timestamp = timestamp
    }
}
