# Text-to-Emoji (TTE)

> NOTE: this is COMPLETELY vibe coded with Claude. Maybe I will learn macOS dev in the future... for now this will do

A macOS status bar app that converts text to emoji like in Discord. Type emoji shortcodes (like `:fire:` or `:heart:`) and they'll automatically be replaced with their corresponding emoji! Features autocomplete suggestions when you type `:` and customizable keyboard shortcuts.

## Features

- **Automatic Text Replacement**: Type `:fire:` and it becomes 🔥
- **Autocomplete**: Type `:` to see emoji suggestions in real-time
- **Discord-Compatible**: Uses the same emoji shortcodes as Discord (250+ emojis)
- **Global Keyboard Shortcuts**: Works across all applications
- **Customizable Keybindings**: Remap shortcuts to your preference
- **Status Bar Interface**: Unobtrusive menu bar app

## Default Keyboard Shortcuts

- **Tab**: Accept autocomplete suggestion
- **Ctrl+Return**: Accept suggestion (alternative)
- **Ctrl+N**: Next suggestion
- **Ctrl+P**: Previous suggestion
- **Ctrl+Shift+T**: Toggle service on/off
- **Cmd+Shift+E**: Toggle settings popover
- **Escape**: Cancel autocomplete

All shortcuts can be customized in the Settings tab.

## Building from Source

### Requirements

- macOS 15.6 or later
- Xcode 16.0 or later
- Command Line Tools for Xcode

### Build Instructions

1. **Clone the repository**
   ```bash
   git clone <your-repo-url>
   cd tte
   ```

2. **Open the project in Xcode**
   ```bash
   open tte.xcodeproj
   ```

3. **Build the app**
   - In Xcode: Product → Build (⌘B)
   - Or via command line:
     ```bash
     xcodebuild -scheme tte -configuration Release build
     ```

4. **Copy to Applications folder**
   ```bash
   cp -R build/Build/Products/Release/tte.app /Applications/
   ```

   If you built in Xcode, the app will be in:
   ```bash
   cp -R ~/Library/Developer/Xcode/DerivedData/tte-*/Build/Products/Release/tte.app /Applications/
   ```

5. **Launch the app**
   ```bash
   open /Applications/tte.app
   ```

### First Launch Setup

1. **Grant Accessibility Permissions** (required for keyboard monitoring)
   - On first launch, the app will show setup instructions
   - Open System Settings → Privacy & Security → Accessibility
   - Click the lock icon (🔒) and enter your password
   - Find "tte" in the list and toggle it ON
   - If "tte" doesn't appear, click the "+" button and manually add it from /Applications/

2. **Enable the service**
   - Click the smiley face icon in your menu bar
   - Click the "Inactive" button to toggle to "Active"
   - Or press Ctrl+Shift+T to toggle from anywhere

3. **Start using emoji!**
   - Type `:fire:` and it becomes 🔥
   - Type `:` to see autocomplete suggestions
   - Browse the emoji list in the app to discover more shortcodes

## Usage

### Autocomplete Mode

1. Type `:` in any application
2. A floating window appears with emoji suggestions
3. Continue typing to filter (e.g., `:fir` shows fire-related emoji)
4. Use Ctrl+N/P to navigate suggestions
5. Press Tab to accept the selected emoji
6. Press Escape to cancel

### Automatic Replacement Mode

Simply type the complete shortcode (e.g., `:sob:`) and it will automatically be replaced with 😭

### Customizing Shortcuts

1. Click the menu bar icon
2. Navigate to the Settings tab
3. Click on any shortcut to record a new key combination
4. Press your desired keys (including modifiers like Ctrl, Cmd, etc.)
5. Click "Reset to Defaults" to restore default shortcuts

## Technical Details

- Built with SwiftUI and Cocoa
- Uses CGEventTap for low-level keyboard event capture
- Requires Accessibility permissions to monitor keyboard input globally
- Persists custom keybindings to UserDefaults
- Clipboard-based text insertion for maximum compatibility

## Troubleshooting

### Keyboard shortcuts not working

- Check that Accessibility permissions are granted
- Try disabling conflicting keyboard customization software (Karabiner, etc.) temporarily
- Some system shortcuts (like Mission Control) may take priority over custom shortcuts
- Try customizing the shortcuts to avoid conflicts

### App doesn't appear in Accessibility settings

- Make sure the app is in /Applications/ (not running from Xcode DerivedData)
- Try launching the app once, then restarting your Mac
- Manually add the app using the "+" button in Accessibility settings

### Autocomplete window doesn't show

- Ensure the service is Active (check menu bar)
- Try toggling the service off and on (Ctrl+Shift+T)
- Check Console.app for error messages (filter for "tte")

## Credits

