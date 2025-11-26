//
//  tteApp.swift
//  tte
//
//  Created by Alex Young on 11/25/25.
//

import SwiftUI

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
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "face.smiling", accessibilityDescription: "Text to Emoji")
            button.action = #selector(togglePopover)
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
