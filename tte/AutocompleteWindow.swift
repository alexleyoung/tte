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

    // MARK: - Constants

    /// Default width of the autocomplete window
    private static let defaultWindowWidth: CGFloat = 300

    /// Default height of the autocomplete window
    private static let defaultWindowHeight: CGFloat = 200

    /// Height of each autocomplete suggestion item
    private static let suggestionItemHeight: CGFloat = 40

    /// Vertical padding for the autocomplete list
    private static let listPadding: CGFloat = 20

    /// Vertical offset from the top of the screen
    private static let topScreenOffset: CGFloat = 100

    private init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: Self.defaultWindowWidth, height: Self.defaultWindowHeight),
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

        let windowWidth: CGFloat = Self.defaultWindowWidth
        let windowHeight: CGFloat = min(CGFloat(suggestions.count) * Self.suggestionItemHeight + Self.listPadding, Self.defaultWindowHeight)

        let screenFrame = screen.visibleFrame
        let x = screenFrame.midX - windowWidth / 2
        let y = screenFrame.maxY - windowHeight - Self.topScreenOffset

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
