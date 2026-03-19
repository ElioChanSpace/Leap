//
//  ShortcutRecorder.swift
//  Leap
//

import SwiftUI
import Carbon
import AppKit
import SwiftUI
import Carbon
import AppKit

class ShortcutRecorderNSView: NSView {
    var onShortcutRecorded: ((Shortcut) -> Void)?
    var isRecording = false {
        didSet { needsDisplay = true }
    }
    
    override var acceptsFirstResponder: Bool { true }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        let color = isRecording ? NSColor.controlAccentColor : NSColor.tertiaryLabelColor
        color.setStroke()
        let path = NSBezierPath(roundedRect: bounds, xRadius: 4, yRadius: 4)
        path.lineWidth = 2
        path.stroke()
        if isRecording {
            NSColor.controlAccentColor.withAlphaComponent(0.1).setFill()
            path.fill()
        }
    }
    
    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        window?.makeFirstResponder(self)
        isRecording = true
    }
    
    override func resignFirstResponder() -> Bool {
        isRecording = false
        return super.resignFirstResponder()
    }
    
    override func keyDown(with event: NSEvent) {
        guard isRecording else {
            super.keyDown(with: event)
            return
        }
        
        if event.keyCode == 53 { // escape
            isRecording = false
            window?.makeFirstResponder(nil)
            return
        }
        
        if event.keyCode == 51 { // delete
            onShortcutRecorded?(Shortcut(keyCode: .max, carbonModifiers: .max, stringRepresentation: "")) 
        }
        
        let modifiers = event.modifierFlags
        let carbonMod = carbonModifierFlags(from: modifiers)
        let shortcut = Shortcut(keyCode: event.keyCode, carbonModifiers: carbonMod, stringRepresentation: stringRepresentation(for: event))
        onShortcutRecorded?(shortcut)
        
        isRecording = false
        window?.makeFirstResponder(nil)
    }
    
    private func carbonModifierFlags(from flags: NSEvent.ModifierFlags) -> UInt32 {
        var carbonFlags: UInt32 = 0
        if flags.contains(.command) { carbonFlags |= UInt32(cmdKey) }
        if flags.contains(.option) { carbonFlags |= UInt32(optionKey) }
        if flags.contains(.control) { carbonFlags |= UInt32(controlKey) }
        if flags.contains(.shift) { carbonFlags |= UInt32(shiftKey) }
        return carbonFlags
    }
    
    private func stringRepresentation(for event: NSEvent) -> String {
        var str = ""
        let flags = event.modifierFlags
        if flags.contains(.control) { str += "⌃" }
        if flags.contains(.option) { str += "⌥" }
        if flags.contains(.shift) { str += "⇧" }
        if flags.contains(.command) { str += "⌘" }
        
        if let chars = event.charactersIgnoringModifiers?.uppercased() {
            str += chars
        }
        return str
    }
}

struct ShortcutRecorder: NSViewRepresentable {
    @Binding var shortcut: Shortcut?
    
    func makeNSView(context: Context) -> ShortcutRecorderNSView {
        let view = ShortcutRecorderNSView()
        view.onShortcutRecorded = { newShortcut in
            self.shortcut = newShortcut
        }
        return view
    }
    
    func updateNSView(_ nsView: ShortcutRecorderNSView, context: Context) {}
}
