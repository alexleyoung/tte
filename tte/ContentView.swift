//
//  ContentView.swift
//  tte
//
//  Created by Alex Young on 11/25/25.
//

import SwiftUI
import ApplicationServices

struct ContentView: View {
    @ObservedObject private var textReplacementService = TextReplacementService.shared
    @State private var hasAccessibilityPermission = false
    @State private var searchText = ""
    @State private var permissionCheckTimer: Timer?
    @State private var selectedTab: ContentTab = .main

    enum ContentTab {
        case main
        case settings
    }

    var filteredShortcuts: [String] {
        let shortcuts = EmojiRegistry.shared.getAllShortcuts()
        if searchText.isEmpty {
            return shortcuts
        }
        return shortcuts.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: { selectedTab = .main }) {
                    Text("Main")
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(selectedTab == .main ? Color.accentColor.opacity(0.2) : Color.clear)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)

                Button(action: { selectedTab = .settings }) {
                    Text("Settings")
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(selectedTab == .settings ? Color.accentColor.opacity(0.2) : Color.clear)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)

                Spacer()
            }
            .padding()
            .background(Color.gray.opacity(0.05))

            if selectedTab == .main {
                mainView
            } else {
                SettingsView()
            }
        }
        .frame(minWidth: 450, minHeight: 600)
        .onAppear {
            hasAccessibilityPermission = textReplacementService.checkAccessibilityPermissions()
            if !hasAccessibilityPermission {
                startPermissionMonitoring()
            }
        }
        .onDisappear {
            stopPermissionMonitoring()
        }
    }

    var mainView: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Text to Emoji")
                    .font(.title)
                    .fontWeight(.bold)

                if !hasAccessibilityPermission {
                VStack(spacing: 15) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.orange)

                    Text("Accessibility Permission Required")
                        .font(.headline)

                    Text("This app needs accessibility permissions to monitor keyboard input and replace text with emojis.")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)

                    Divider()
                        .padding(.vertical, 5)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Setup Instructions:")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        HStack(alignment: .top, spacing: 8) {
                            Text("1.")
                                .fontWeight(.medium)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Click the button below to open Accessibility settings")
                                Button("Open Accessibility Settings") {
                                    NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.small)
                            }
                        }

                        HStack(alignment: .top, spacing: 8) {
                            Text("2.")
                                .fontWeight(.medium)
                            Text("Click the lock icon (🔒) at the bottom and enter your password")
                        }

                        HStack(alignment: .top, spacing: 8) {
                            Text("3.")
                                .fontWeight(.medium)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Look for \"tte\" in the list. If not found:")
                                Text("• Click the \"+\" button")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("• Navigate to Applications folder")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("• Select \"tte\" and click Open")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        HStack(alignment: .top, spacing: 8) {
                            Text("4.")
                                .fontWeight(.medium)
                            Text("Toggle the checkbox next to \"tte\" to ON")
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    .font(.system(size: 13))

                    Text("This screen will automatically update once permission is granted.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 5)
                }
                .padding()
            } else {
                VStack(spacing: 15) {
                    Button(action: {
                        if textReplacementService.isEnabled {
                            textReplacementService.stop()
                        } else {
                            textReplacementService.start()
                        }
                    }) {
                        HStack {
                            Image(systemName: textReplacementService.isEnabled ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(textReplacementService.isEnabled ? .green : .gray)
                                .font(.title2)

                            Text(textReplacementService.isEnabled ? "Active" : "Inactive")
                                .font(.headline)
                                .foregroundColor(.primary)

                            Spacer()
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                    }
                    .buttonStyle(.plain)

                    Divider()

                    Text("Available Emoji Shortcuts")
                        .font(.headline)

                    TextField("Search shortcuts...", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())

                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 8) {
                            ForEach(filteredShortcuts, id: \.self) { shortcut in
                                if let emoji = EmojiRegistry.shared.getEmoji(for: shortcut) {
                                    HStack {
                                        Text(emoji)
                                            .font(.title)
                                        Text(shortcut)
                                            .font(.system(.body, design: .monospaced))
                                            .foregroundColor(.secondary)
                                        Spacer()
                                    }
                                    .padding(.vertical, 4)
                                    .padding(.horizontal, 8)
                                    .background(Color.gray.opacity(0.05))
                                    .cornerRadius(5)
                                }
                            }
                        }
                    }
                    .frame(maxHeight: 300)
                }
                .padding()
                }
            }
            .padding()
        }
    }

    private func startPermissionMonitoring() {
        stopPermissionMonitoring()

        permissionCheckTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            let hasPermission = textReplacementService.checkAccessibilityPermissions()
            if hasPermission != hasAccessibilityPermission {
                hasAccessibilityPermission = hasPermission
                if hasPermission {
                    stopPermissionMonitoring()
                }
            }
        }
    }

    private func stopPermissionMonitoring() {
        permissionCheckTimer?.invalidate()
        permissionCheckTimer = nil
    }

    private func requestAccessibilityPermission() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true]
        let accessEnabled = AXIsProcessTrustedWithOptions(options)

        if !accessEnabled {
            // Attempt to create a global event monitor to force registration
            let dummyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { _ in }
            if let monitor = dummyMonitor {
                NSEvent.removeMonitor(monitor)
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
            }
        }
    }
}

#Preview {
    ContentView()
}
