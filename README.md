# tte (text-to-emoji)

> vibe coded with claude. i might learn macOS dev properly someday. for now, this works.

a little menu bar app that does text emoji replacements. type `:sob:` and get 😭 (#1 use case). that's it.

## why this exists

i was tired of copying emojis from the internet or hunting through the macOS emoji picker. discord and slack's `:shortcode:` system is muscle memory at this point, so i (claude) made it work everywhere.

## what it does

- type emoji shortcodes (`:fire:`, `:heart:`, etc.) and they auto-replace with the actual emoji
- autocomplete when you hit `:` - shows suggestions as you type acceptable via customizable keymaps
- learns what you use most and surfaces those first
- case-insensitive search
- 250+ discord emoji shortcodes (i think its accurate, claude did this. u can always manually edit the map in `EmojiRegistry`)
- global keyboard shortcuts
- sits in your menu bar, stays out of your way

## shortcuts

you can remap all of these, but here's the defaults:

- `Tab` - accept autocomplete
- `Ctrl+Return` - also accepts (this is currently bugged, use tab)
- `Ctrl+N` / `Ctrl+P` - navigate suggestions
- `Ctrl+Shift+T` - toggle the whole thing on/off
- `Ctrl+Shift+H` - open the emoji picker UI
- `Escape` - cancel autocomplete

## building it

you need macOS 15.6+ and Xcode 16+

### quick way

```bash
git clone <your-repo-url>
cd tte
make install
open /Applications/tte.app
```

the makefile builds in release mode and drops it in `/Applications`. done.

other commands: `make build`, `make clean`, `make help`

### manual way

```bash
git clone <your-repo-url>
cd tte
open tte.xcodeproj
```

then either build in Xcode (⌘B) or:

```bash
xcodebuild -scheme tte -configuration Release build
sudo cp -R build/Build/Products/Release/tte.app /Applications/
```

if you built in Xcode, the app's buried in DerivedData:

```bash
sudo cp -R ~/Library/Developer/Xcode/DerivedData/tte-*/Build/Products/Release/tte.app /Applications/
```

then:

```bash
open /Applications/tte.app
```

## first time setup

1. **grant accessibility permissions** (required)
   - the app will tell you this on first launch
   - System Settings → Privacy & Security → Accessibility
   - unlock (🔒), find "tte", toggle it on
   - if it's not there, hit "+" and add it from /Applications

2. **turn it on**
   - click the menu bar icon
   - toggle from "Inactive" to "Active"
   - or just hit `Ctrl+Shift+H` from anywhere

3. **use it**
   - type `:fire:` → 🔥
   - type `:` → see all your options
   - the more you use something, the higher it ranks

## how to use it

### autocomplete

- type `:` anywhere
- floating window shows emoji (sorted by what you use most)
- keep typing to filter (`:fir` finds fire-related stuff)
- works case-insensitive - `:FIRE:` = `:fire:`
- `Ctrl+N`/`Ctrl+P` to navigate
- `Tab` to insert
- `Escape` to bail

the app counts your emojis used and your completes will sort accordingly.

### auto-replace

just type the full shortcode. `:sob:` becomes 😭 immediately.

### customizing shortcuts

click the menu bar → settings tab → click any shortcut → press your new keys → done.

hit "Reset to Defaults" if you mess it up.

## technical stuff

- SwiftUI + Cocoa
- CGEventTap for system-wide keyboard capture
- needs accessibility permissions to monitor keystrokes globally
- uses clipboard for insertion (maximum app compatibility)
- keybindings persist to UserDefaults
- emoji usage stats persist too

## troubleshooting

**shortcuts don't work**
- check accessibility permissions are actually on
- disable conflicting keyboard tools (karabiner, etc.) temporarily
- some system shortcuts override custom ones - try remapping
- restart the app

**app not in accessibility settings**
- make sure it's in /Applications (not running from Xcode build folder)
- launch once, then restart your mac
- manually add it with the "+" button

**autocomplete doesn't show**
- check if it's Active in the menu bar
- toggle off/on with `Ctrl+Shift+H`
- check Console.app, filter for "tte" to see errors

## credits

claude 4.5 sonnet for making this work and whoever invented the :shortcode: system
