//
//  SettingsView.swift
//  tte
//
//  Created by Alex Young on 11/25/25.
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var settings = SettingsManager.shared
    @State private var recordingKey: KeyBindingType?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Settings")
                    .font(.title)
                    .fontWeight(.bold)

                VStack(alignment: .leading, spacing: 15) {
                Text("Keyboard Shortcuts")
                    .font(.headline)

                KeyBindingRow(
                    title: "Accept Suggestion",
                    binding: settings.acceptKey,
                    isRecording: recordingKey == .accept,
                    onRecord: { recordingKey = .accept }
                )

                KeyBindingRow(
                    title: "Accept Suggestion (Alt)",
                    binding: settings.acceptKeyAlt,
                    isRecording: recordingKey == .acceptAlt,
                    onRecord: { recordingKey = .acceptAlt }
                )

                KeyBindingRow(
                    title: "Next Suggestion",
                    binding: settings.nextKey,
                    isRecording: recordingKey == .next,
                    onRecord: { recordingKey = .next }
                )

                KeyBindingRow(
                    title: "Previous Suggestion",
                    binding: settings.previousKey,
                    isRecording: recordingKey == .previous,
                    onRecord: { recordingKey = .previous }
                )

                KeyBindingRow(
                    title: "Toggle Popover",
                    binding: settings.togglePopoverKey,
                    isRecording: recordingKey == .togglePopover,
                    onRecord: { recordingKey = .togglePopover }
                )
            }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)

                Button("Reset to Defaults") {
                    resetToDefaults()
                }
                .padding(.top, 10)
            }
            .padding()
        }
        .background(KeyEventHandlerView(recordingKey: $recordingKey, onKeyPress: handleKeyPress))
    }

    private func resetToDefaults() {
        settings.acceptKey = KeyBinding(keyCode: 48, modifiers: [], label: "Tab")
        settings.acceptKeyAlt = KeyBinding(keyCode: 36, modifiers: [.control], label: "⌃Return")
        settings.nextKey = KeyBinding(keyCode: 45, modifiers: [.control], label: "⌃N")
        settings.previousKey = KeyBinding(keyCode: 35, modifiers: [.control], label: "⌃P")
        settings.togglePopoverKey = KeyBinding(keyCode: 14, modifiers: [.command, .shift], label: "⌘⇧E")
        settings.saveSettings()
        recordingKey = nil
    }

    private func handleKeyPress(event: NSEvent) {
        guard let recording = recordingKey else { return }

        let keyCode = event.keyCode
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)

        // Check if only modifier keys were pressed (no actual key)
        let isModifierOnly = isModifierKeyCode(keyCode)

        // If it's just a modifier key press without an actual key, wait for more input
        if isModifierOnly {
            return
        }

        var modifiers: [ModifierKey] = []
        if flags.contains(.command) { modifiers.append(.command) }
        if flags.contains(.option) { modifiers.append(.option) }
        if flags.contains(.control) { modifiers.append(.control) }
        if flags.contains(.shift) { modifiers.append(.shift) }

        let label = createLabel(keyCode: keyCode, modifiers: modifiers)
        let newBinding = KeyBinding(keyCode: keyCode, modifiers: modifiers, label: label)

        switch recording {
        case .accept:
            settings.acceptKey = newBinding
        case .acceptAlt:
            settings.acceptKeyAlt = newBinding
        case .next:
            settings.nextKey = newBinding
        case .previous:
            settings.previousKey = newBinding
        case .togglePopover:
            settings.togglePopoverKey = newBinding
        }

        settings.saveSettings()
        recordingKey = nil
    }

    private func isModifierKeyCode(_ keyCode: UInt16) -> Bool {
        // Modifier key codes
        let modifierKeyCodes: [UInt16] = [
            54, 55,  // Command (left, right)
            58, 61,  // Option (left, right)
            59, 62,  // Control (left, right)
            56, 60   // Shift (left, right)
        ]
        return modifierKeyCodes.contains(keyCode)
    }

    private func createLabel(keyCode: UInt16, modifiers: [ModifierKey]) -> String {
        var parts: [String] = []

        for modifier in modifiers {
            parts.append(modifier.displayName)
        }

        let keyName = keyCodeToString(keyCode)
        parts.append(keyName)

        return parts.joined(separator: "")
    }

    private func keyCodeToString(_ keyCode: UInt16) -> String {
        switch keyCode {
        case 0: return "A"
        case 11: return "B"
        case 8: return "C"
        case 2: return "D"
        case 14: return "E"
        case 3: return "F"
        case 5: return "G"
        case 4: return "H"
        case 34: return "I"
        case 38: return "J"
        case 40: return "K"
        case 37: return "L"
        case 46: return "M"
        case 45: return "N"
        case 31: return "O"
        case 35: return "P"
        case 12: return "Q"
        case 15: return "R"
        case 1: return "S"
        case 17: return "T"
        case 32: return "U"
        case 9: return "V"
        case 13: return "W"
        case 7: return "X"
        case 16: return "Y"
        case 6: return "Z"
        case 48: return "Tab"
        case 36: return "Return"
        case 49: return "Space"
        case 51: return "Delete"
        case 53: return "Escape"
        case 123: return "←"
        case 124: return "→"
        case 125: return "↓"
        case 126: return "↑"
        default: return "Key\(keyCode)"
        }
    }
}

enum KeyBindingType {
    case accept
    case acceptAlt
    case next
    case previous
    case togglePopover
}

struct KeyBindingRow: View {
    let title: String
    let binding: KeyBinding
    let isRecording: Bool
    let onRecord: () -> Void

    var body: some View {
        HStack {
            Text(title)
                .frame(width: 180, alignment: .leading)

            Spacer()

            Button(action: onRecord) {
                Text(isRecording ? "Press any key..." : binding.label)
                    .frame(width: 150)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(isRecording ? Color.accentColor.opacity(0.3) : Color.gray.opacity(0.2))
                    .cornerRadius(5)
            }
            .buttonStyle(.plain)
        }
    }
}

struct KeyEventHandlerView: NSViewRepresentable {
    @Binding var recordingKey: KeyBindingType?
    let onKeyPress: (NSEvent) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = KeyEventHandlingNSView()
        view.recordingKey = recordingKey
        view.onKeyPress = onKeyPress
        DispatchQueue.main.async {
            view.window?.makeFirstResponder(view)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        if let view = nsView as? KeyEventHandlingNSView {
            view.recordingKey = recordingKey
        }
    }
}

class KeyEventHandlingNSView: NSView {
    var recordingKey: KeyBindingType?
    var onKeyPress: ((NSEvent) -> Void)?
    private var currentModifiers: NSEvent.ModifierFlags = []

    override var acceptsFirstResponder: Bool { true }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window != nil {
            window?.makeFirstResponder(self)
        }
    }

    override func keyDown(with event: NSEvent) {
        if recordingKey != nil {
            onKeyPress?(event)
        } else {
            super.keyDown(with: event)
        }
    }

    override func flagsChanged(with event: NSEvent) {
        if recordingKey != nil {
            currentModifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        } else {
            super.flagsChanged(with: event)
        }
    }
}
