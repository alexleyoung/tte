//
//  SettingsManager.swift
//  tte
//
//  Created by Alex Young on 11/25/25.
//

import Foundation
import Carbon
import Combine
import Cocoa

/// Manages keyboard shortcut settings and persists them to UserDefaults.
class SettingsManager: ObservableObject {
    static let shared = SettingsManager()

    @Published var acceptKey: KeyBinding = KeyBinding(keyCode: KeyCode.tab, modifiers: [], label: "Tab")
    @Published var acceptKeyAlt: KeyBinding = KeyBinding(keyCode: KeyCode.return, modifiers: [.control], label: "⌃Return")
    @Published var nextKey: KeyBinding = KeyBinding(keyCode: KeyCode.n, modifiers: [.control], label: "⌃N")
    @Published var previousKey: KeyBinding = KeyBinding(keyCode: KeyCode.p, modifiers: [.control], label: "⌃P")
    @Published var togglePopoverKey: KeyBinding = KeyBinding(keyCode: KeyCode.h, modifiers: [.control, .shift], label: "⌃⇧H")
    @Published var toggleServiceKey: KeyBinding = KeyBinding(keyCode: KeyCode.t, modifiers: [.control, .shift], label: "⌃⇧T")

    private init() {
        loadSettings()
    }

    func loadSettings() {
        if let acceptData = UserDefaults.standard.data(forKey: "acceptKey"),
           let binding = try? JSONDecoder().decode(KeyBinding.self, from: acceptData) {
            acceptKey = binding
        }

        if let acceptAltData = UserDefaults.standard.data(forKey: "acceptKeyAlt"),
           let binding = try? JSONDecoder().decode(KeyBinding.self, from: acceptAltData) {
            acceptKeyAlt = binding
        }

        if let nextData = UserDefaults.standard.data(forKey: "nextKey"),
           let binding = try? JSONDecoder().decode(KeyBinding.self, from: nextData) {
            nextKey = binding
        }

        if let previousData = UserDefaults.standard.data(forKey: "previousKey"),
           let binding = try? JSONDecoder().decode(KeyBinding.self, from: previousData) {
            previousKey = binding
        }

        if let toggleData = UserDefaults.standard.data(forKey: "togglePopoverKey"),
           let binding = try? JSONDecoder().decode(KeyBinding.self, from: toggleData) {
            togglePopoverKey = binding
        }

        if let toggleServiceData = UserDefaults.standard.data(forKey: "toggleServiceKey"),
           let binding = try? JSONDecoder().decode(KeyBinding.self, from: toggleServiceData) {
            toggleServiceKey = binding
        }
    }

    func saveSettings() {
        if let data = try? JSONEncoder().encode(acceptKey) {
            UserDefaults.standard.set(data, forKey: "acceptKey")
        }

        if let data = try? JSONEncoder().encode(acceptKeyAlt) {
            UserDefaults.standard.set(data, forKey: "acceptKeyAlt")
        }

        if let data = try? JSONEncoder().encode(nextKey) {
            UserDefaults.standard.set(data, forKey: "nextKey")
        }

        if let data = try? JSONEncoder().encode(previousKey) {
            UserDefaults.standard.set(data, forKey: "previousKey")
        }

        if let data = try? JSONEncoder().encode(togglePopoverKey) {
            UserDefaults.standard.set(data, forKey: "togglePopoverKey")
        }

        if let data = try? JSONEncoder().encode(toggleServiceKey) {
            UserDefaults.standard.set(data, forKey: "toggleServiceKey")
        }
    }
}

/// Represents a keyboard shortcut binding with a key code and modifier keys.
struct KeyBinding: Codable, Equatable {
    let keyCode: UInt16
    let modifiers: [ModifierKey]
    let label: String

    /// Checks if this key binding matches a given keyboard event.
    /// - Parameter event: The NSEvent to check
    /// - Returns: true if the event matches this binding
    func matches(event: NSEvent) -> Bool {
        guard event.keyCode == keyCode else { return false }

        let eventModifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        let requiredModifiers = modifiers.reduce(NSEvent.ModifierFlags()) { result, modifier in
            result.union(modifier.flag)
        }

        return eventModifiers == requiredModifiers
    }
}

enum ModifierKey: String, Codable, CaseIterable {
    case command
    case option
    case control
    case shift

    var flag: NSEvent.ModifierFlags {
        switch self {
        case .command: return .command
        case .option: return .option
        case .control: return .control
        case .shift: return .shift
        }
    }

    var displayName: String {
        switch self {
        case .command: return "⌘"
        case .option: return "⌥"
        case .control: return "⌃"
        case .shift: return "⇧"
        }
    }
}
