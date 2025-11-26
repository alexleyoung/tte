//
//  tteApp.swift
//  tte
//
//  Created by Alex Young on 11/25/25.
//

import SwiftUI
import Combine

@main
struct tteApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

extension Notification.Name {
    static let togglePopover = Notification.Name("togglePopover")
    static let toggleService = Notification.Name("toggleService")
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize the TextReplacementService singleton to set up global event tap
        _ = TextReplacementService.shared

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "face.smiling", accessibilityDescription: "Text to Emoji")
            button.action = #selector(handleLeftClick)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.target = self
        }

        popover = NSPopover()
        popover?.contentSize = NSSize(width: 450, height: 600)
        popover?.behavior = .transient
        popover?.contentViewController = NSHostingController(rootView: ContentView())

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(togglePopover),
            name: .togglePopover,
            object: nil
        )

        // Observe service state changes to update icon color
        TextReplacementService.shared.$isEnabled
            .sink { [weak self] isEnabled in
                self?.updateStatusIconColor(isEnabled: isEnabled)
            }
            .store(in: &cancellables)
    }

    private func updateStatusIconColor(isEnabled: Bool) {
        guard let button = statusItem?.button else { return }

        let config = NSImage.SymbolConfiguration(paletteColors: isEnabled ? [.systemGreen] : [.labelColor])
        button.image = NSImage(systemSymbolName: "face.smiling", accessibilityDescription: "Text to Emoji")?.withSymbolConfiguration(config)
    }

    @objc func handleLeftClick() {
        guard let event = NSApp.currentEvent else { return }

        if event.type == .rightMouseUp {
            showContextMenu()
        } else {
            togglePopover()
        }
    }

    func showContextMenu() {
        let menu = NSMenu()

        menu.addItem(NSMenuItem(title: "Open TTE", action: #selector(togglePopover), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit TTE", action: #selector(quitApp), keyEquivalent: "q"))

        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)
        statusItem?.menu = nil
    }

    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
    }

    @objc func togglePopover() {
        if let button = statusItem?.button {
            if let popover = popover {
                if popover.isShown {
                    popover.performClose(nil)
                } else {
                    popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                }
            }
        }
    }
}
