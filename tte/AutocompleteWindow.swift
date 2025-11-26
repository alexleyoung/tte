//
//  AutocompleteWindow.swift
//  tte
//
//  Created by Alex Young on 11/25/25.
//

import SwiftUI
import Cocoa

class AutocompleteWindowController: NSWindowController {
    static let shared = AutocompleteWindowController()

    private init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 200),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .stationary]
        window.hasShadow = true

        super.init(window: window)

        window.contentView = NSHostingView(rootView: AutocompleteView())
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func show(suggestions: [EmojiSuggestion], selectedIndex: Int) {
        guard let screen = NSScreen.main else { return }

        let windowWidth: CGFloat = 300
        let windowHeight: CGFloat = min(CGFloat(suggestions.count * 40 + 20), 200)

        let screenFrame = screen.visibleFrame
        let x = screenFrame.midX - windowWidth / 2
        let y = screenFrame.maxY - windowHeight - 100

        window?.setFrame(NSRect(x: x, y: y, width: windowWidth, height: windowHeight), display: true)

        if let hostingView = window?.contentView as? NSHostingView<AutocompleteView> {
            hostingView.rootView = AutocompleteView(suggestions: suggestions, selectedIndex: selectedIndex)
        }

        window?.orderFrontRegardless()
    }

    func hide() {
        window?.orderOut(nil)
    }
}

struct EmojiSuggestion: Identifiable {
    let id = UUID()
    let shortcode: String
    let emoji: String
}

struct AutocompleteView: View {
    var suggestions: [EmojiSuggestion] = []
    var selectedIndex: Int = 0

    var body: some View {
        VStack(spacing: 0) {
            if suggestions.isEmpty {
                Text("No matches")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 2) {
                            ForEach(Array(suggestions.enumerated()), id: \.element.id) { index, suggestion in
                                HStack(spacing: 10) {
                                    Text(suggestion.emoji)
                                        .font(.title2)

                                    Text(suggestion.shortcode)
                                        .font(.system(.body, design: .monospaced))
                                        .foregroundColor(.primary)

                                    Spacer()
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(index == selectedIndex ? Color.accentColor.opacity(0.3) : Color.clear)
                                .cornerRadius(6)
                                .id(index)
                            }
                        }
                        .padding(8)
                    }
                    .onChange(of: selectedIndex) { oldValue, newValue in
                        withAnimation(.easeInOut(duration: 0.2)) {
                            proxy.scrollTo(newValue, anchor: .center)
                        }
                    }
                    .onAppear {
                        proxy.scrollTo(selectedIndex, anchor: .center)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(NSColor.windowBackgroundColor))
                .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 2)
        )
    }
}
