import Foundation

struct Shortcut: Codable, Equatable {
    var keyCode: UInt16
    var carbonModifiers: UInt32
    var stringRepresentation: String
    
    public init(keyCode: UInt16, carbonModifiers: UInt32, stringRepresentation: String) {
        self.keyCode = keyCode
        self.carbonModifiers = carbonModifiers
        self.stringRepresentation = stringRepresentation
    }
}
