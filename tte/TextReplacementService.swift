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
    static let shared = TextReplacementService()

    @Published var isEnabled = false
    private var eventMonitor: Any?
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var toggleServiceMonitor: Any?
    private var currentBuffer = ""
    private let maxBufferLength = 50

    private var autocompleteActive = false
    private var autocompletePrefix = ""
    private var suggestions: [EmojiSuggestion] = []
    private var selectedSuggestionIndex = 0

    private init() {
        setupGlobalToggleMonitor()
    }

    func start() {
        guard !isEnabled else { return }

        if !AXIsProcessTrusted() {
            requestAccessibilityPermissions()
            return
        }

        // Global monitor for key events in other apps
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyEvent(event)
        }

        // Create event tap for capturing shortcuts even when other apps have focus
        startEventTap()

        isEnabled = true
    }

    func stop() {
        guard isEnabled else { return }

        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }

        stopEventTap()

        currentBuffer = ""
        hideAutocomplete()
        isEnabled = false
    }

    private func startEventTap() {
        let eventMask = (1 << CGEventType.keyDown.rawValue)

        print("Attempting to create event tap...")

        guard let eventTap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                guard let refcon = refcon else { return Unmanaged.passUnretained(event) }
                let service = Unmanaged<TextReplacementService>.fromOpaque(refcon).takeUnretainedValue()
                return service.handleEventTap(proxy: proxy, type: type, event: event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            print("❌ FAILED to create event tap - this likely means accessibility permissions are not granted or event tap is blocked")
            return
        }

        print("✅ Event tap created successfully!")

        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)

        print("Event tap enabled and added to run loop")

        self.eventTap = eventTap
        self.runLoopSource = runLoopSource
    }

    private func stopEventTap() {
        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
            if let runLoopSource = runLoopSource {
                CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
            }
            self.eventTap = nil
            self.runLoopSource = nil
        }
    }

    private func handleEventTap(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        guard type == .keyDown else {
            return Unmanaged.passUnretained(event)
        }

        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        let flags = event.flags

        let nsEvent = NSEvent(cgEvent: event)
        let settings = SettingsManager.shared

        #if DEBUG
        print("Event tap - keyCode: \(keyCode), flags: \(flags), chars: \(nsEvent?.characters ?? "nil")")
        #endif

        // Check for toggle popover shortcut
        if let nsEvent = nsEvent, settings.togglePopoverKey.matches(event: nsEvent) {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .togglePopover, object: nil)
            }
            return nil // Consume event
        }

        // Note: Toggle service shortcut is handled by setupGlobalToggleMonitor()
        // so it works even when the service is disabled

        // Check autocomplete shortcuts
        if autocompleteActive {
            #if DEBUG
            print("Autocomplete active in event tap")
            #endif

            if let nsEvent = nsEvent {
                if settings.acceptKey.matches(event: nsEvent) || settings.acceptKeyAlt.matches(event: nsEvent) {
                    #if DEBUG
                    print("Accept key matched in event tap!")
                    #endif
                    DispatchQueue.main.async { [weak self] in
                        self?.acceptSuggestion()
                    }
                    return nil // Consume event
                }

                if settings.nextKey.matches(event: nsEvent) {
                    #if DEBUG
                    print("Next key matched in event tap!")
                    #endif
                    DispatchQueue.main.async { [weak self] in
                        self?.selectNextSuggestion()
                    }
                    return nil // Consume event
                }

                if settings.previousKey.matches(event: nsEvent) {
                    #if DEBUG
                    print("Previous key matched in event tap!")
                    #endif
                    DispatchQueue.main.async { [weak self] in
                        self?.selectPreviousSuggestion()
                    }
                    return nil // Consume event
                }

                // Escape key
                if keyCode == 53 {
                    DispatchQueue.main.async { [weak self] in
                        self?.hideAutocomplete()
                    }
                }
            }
        }

        return Unmanaged.passUnretained(event)
    }

    private func handleKeyEvent(_ event: NSEvent) {
        guard let characters = event.characters else { return }

        for char in characters {
            if char == "\r" || char == "\n" {
                currentBuffer = ""
                hideAutocomplete()
                continue
            }

            if char == "\u{7F}" {
                if !currentBuffer.isEmpty {
                    currentBuffer.removeLast()
                    if autocompleteActive {
                        updateAutocomplete()
                    }
                }
                continue
            }

            if char == " " {
                hideAutocomplete()
            }

            currentBuffer.append(char)

            if currentBuffer.count > maxBufferLength {
                currentBuffer.removeFirst()
            }

            if autocompleteActive {
                updateAutocomplete()
            } else {
                checkForAutocompleteStart()
            }

            checkForEmojiShortcut()
        }
    }

    private func checkForAutocompleteStart() {
        if let lastColonIndex = currentBuffer.lastIndex(of: ":") {
            let afterColon = currentBuffer[currentBuffer.index(after: lastColonIndex)...]
            if !afterColon.contains(" ") && afterColon.count >= 0 {
                autocompletePrefix = ":" + String(afterColon)
                startAutocomplete()
            }
        }
    }

    private func startAutocomplete() {
        autocompleteActive = true
        updateAutocomplete()
    }

    private func updateAutocomplete() {
        if let lastColonIndex = currentBuffer.lastIndex(of: ":") {
            let afterColon = currentBuffer[currentBuffer.index(after: lastColonIndex)...]
            autocompletePrefix = ":" + String(afterColon)

            if autocompletePrefix == ":" {
                suggestions = EmojiRegistry.shared.getAllShortcuts()
                    .prefix(10)
                    .compactMap { shortcode in
                        guard let emoji = EmojiRegistry.shared.getEmoji(for: shortcode) else { return nil }
                        return EmojiSuggestion(shortcode: shortcode, emoji: emoji)
                    }
            } else {
                suggestions = EmojiRegistry.shared.getAllShortcuts()
                    .filter { $0.hasPrefix(autocompletePrefix) }
                    .prefix(10)
                    .compactMap { shortcode in
                        guard let emoji = EmojiRegistry.shared.getEmoji(for: shortcode) else { return nil }
                        return EmojiSuggestion(shortcode: shortcode, emoji: emoji)
                    }
            }

            selectedSuggestionIndex = 0

            if suggestions.isEmpty {
                hideAutocomplete()
            } else {
                showAutocomplete()
            }
        } else {
            hideAutocomplete()
        }
    }

    private func showAutocomplete() {
        DispatchQueue.main.async {
            AutocompleteWindowController.shared.show(suggestions: self.suggestions, selectedIndex: self.selectedSuggestionIndex)
        }
    }

    private func hideAutocomplete() {
        autocompleteActive = false
        autocompletePrefix = ""
        suggestions = []
        selectedSuggestionIndex = 0
        DispatchQueue.main.async {
            AutocompleteWindowController.shared.hide()
        }
    }

    private func selectNextSuggestion() {
        guard !suggestions.isEmpty else { return }
        selectedSuggestionIndex = (selectedSuggestionIndex + 1) % suggestions.count
        showAutocomplete()
    }

    private func selectPreviousSuggestion() {
        guard !suggestions.isEmpty else { return }
        selectedSuggestionIndex = (selectedSuggestionIndex - 1 + suggestions.count) % suggestions.count
        showAutocomplete()
    }

    private func acceptSuggestion() {
        guard selectedSuggestionIndex < suggestions.count else { return }
        let suggestion = suggestions[selectedSuggestionIndex]

        #if DEBUG
        print("Accepting suggestion: \(suggestion.emoji), deleting \(autocompletePrefix.count) characters for prefix '\(autocompletePrefix)'")
        #endif

        let deleteCount = autocompletePrefix.count
        for _ in 0..<deleteCount {
            simulateKeyPress(keyCode: CGKeyCode(kVK_Delete))
        }

        // Small delay to ensure deletions complete before pasting
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            guard let self = self else { return }
            self.pasteText(suggestion.emoji)

            if self.currentBuffer.count >= self.autocompletePrefix.count {
                let startIndex = self.currentBuffer.index(self.currentBuffer.endIndex, offsetBy: -self.autocompletePrefix.count)
                self.currentBuffer.removeSubrange(startIndex..<self.currentBuffer.endIndex)
            } else {
                self.currentBuffer = ""
            }

            self.currentBuffer.append(suggestion.emoji)
            self.hideAutocomplete()
        }
    }

    private func checkForEmojiShortcut() {
        for (shortcut, emoji) in EmojiRegistry.shared.mappings {
            if currentBuffer.hasSuffix(shortcut) {
                replaceWithEmoji(shortcut: shortcut, emoji: emoji)
                hideAutocomplete()
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

    private func setupGlobalToggleMonitor() {
        // This monitor is always active to catch the toggle service shortcut
        toggleServiceMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return }
            let settings = SettingsManager.shared

            if settings.toggleServiceKey.matches(event: event) {
                DispatchQueue.main.async {
                    if self.isEnabled {
                        self.stop()
                    } else {
                        self.start()
                    }
                }
            }
        }
    }
}
