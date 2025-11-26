//
//  TextReplacementService.swift
//  tte
//
//  Created by Alex Young on 11/25/25.
//

import Cocoa
import Carbon
import Combine

class TextReplacementService: ObservableObject {
    @Published var isEnabled = false
    private var eventMonitor: Any?
    private var currentBuffer = ""
    private let maxBufferLength = 50

    func start() {
        guard !isEnabled else { return }

        if !AXIsProcessTrusted() {
            requestAccessibilityPermissions()
            return
        }

        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyEvent(event)
        }

        isEnabled = true
    }

    func stop() {
        guard isEnabled else { return }

        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }

        currentBuffer = ""
        isEnabled = false
    }

    private func handleKeyEvent(_ event: NSEvent) {
        guard let characters = event.characters else { return }

        for char in characters {
            if char == "\r" || char == "\n" {
                currentBuffer = ""
                continue
            }

            if char == "\u{7F}" {
                if !currentBuffer.isEmpty {
                    currentBuffer.removeLast()
                }
                continue
            }

            currentBuffer.append(char)

            if currentBuffer.count > maxBufferLength {
                currentBuffer.removeFirst()
            }

            checkForEmojiShortcut()
        }
    }

    private func checkForEmojiShortcut() {
        for (shortcut, emoji) in EmojiRegistry.shared.mappings {
            if currentBuffer.hasSuffix(shortcut) {
                replaceWithEmoji(shortcut: shortcut, emoji: emoji)
                break
            }
        }
    }

    private func replaceWithEmoji(shortcut: String, emoji: String) {
        let deleteCount = shortcut.count

        for _ in 0..<deleteCount {
            simulateKeyPress(keyCode: CGKeyCode(kVK_Delete))
        }

        pasteText(emoji)

        if currentBuffer.count >= shortcut.count {
            let startIndex = currentBuffer.index(currentBuffer.endIndex, offsetBy: -shortcut.count)
            currentBuffer.removeSubrange(startIndex..<currentBuffer.endIndex)
        } else {
            currentBuffer = ""
        }

        currentBuffer.append(emoji)
    }

    private func simulateKeyPress(keyCode: CGKeyCode) {
        let source = CGEventSource(stateID: .hidSystemState)

        if let keyDownEvent = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true),
           let keyUpEvent = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false) {
            keyDownEvent.post(tap: .cghidEventTap)
            keyUpEvent.post(tap: .cghidEventTap)
        }
    }

    private func pasteText(_ text: String) {
        let pasteboard = NSPasteboard.general
        let previousContents = pasteboard.string(forType: .string)

        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        let source = CGEventSource(stateID: .hidSystemState)
        if let vKeyDown = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_Command), keyDown: true),
           let pasteKeyDown = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: true),
           let pasteKeyUp = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: false),
           let vKeyUp = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_Command), keyDown: false) {

            pasteKeyDown.flags = .maskCommand
            pasteKeyUp.flags = .maskCommand

            vKeyDown.post(tap: .cghidEventTap)
            pasteKeyDown.post(tap: .cghidEventTap)
            pasteKeyUp.post(tap: .cghidEventTap)
            vKeyUp.post(tap: .cghidEventTap)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            pasteboard.clearContents()
            if let previousContents = previousContents {
                pasteboard.setString(previousContents, forType: .string)
            }
        }
    }

    private func requestAccessibilityPermissions() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true]
        AXIsProcessTrustedWithOptions(options)
    }

    func checkAccessibilityPermissions() -> Bool {
        return AXIsProcessTrusted()
    }
}
