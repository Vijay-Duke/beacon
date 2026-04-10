# Beacon

A macOS screen laser pointer for presentations and screen sharing.

Double-tap and hold a hotkey to highlight anything on your screen. Works with any screen-sharing tool (Zoom, Meet, Teams, etc.) because it draws directly on the screen as a transparent overlay.

## Features

**4 pointer styles:**
- **Classic Dot** -- bright colored dot with a trailing comet-tail effect
- **Spotlight** -- dims the entire screen except a circle around your cursor
- **Glowing Halo** -- a pulsing ring that draws attention without obscuring content
- **Crosshair** -- precise targeting lines for pinpointing exact elements

**Configurable:**
- Hotkey: any modifier key (Shift, Control, Option, Command, Fn) or function key (F1-F12)
- Activation: double-tap and hold to activate, release to deactivate
- Color: red, green, blue, amber, white
- Size, trail length, spotlight opacity, halo pulse speed, crosshair thickness

**macOS native:**
- Swift + AppKit overlay, SwiftUI preferences
- Menu bar app (no dock icon)
- Right-click context menu for quick style/color switching while active
- Multi-monitor support
- Works over fullscreen apps
- Lightweight (~2MB)

## Install

### Build from source

Requires Xcode Command Line Tools and macOS 14+.

```bash
git clone https://github.com/YOUR_USERNAME/beacon.git
cd beacon
./install.sh
```

This builds a release binary and installs `Beacon.app` to `~/Applications/`.

### Run from source (development)

```bash
swift build && .build/debug/Beacon
```

## Usage

1. Launch Beacon -- a circle icon appears in the menu bar
2. **Double-tap and hold Left Shift** (default) to activate the laser pointer
3. Move your mouse to point at things on screen
4. Release the key to deactivate
5. Right-click while active to quickly switch styles or colors

### Permissions

On first launch, macOS will ask for **Accessibility** permission (System Settings > Privacy & Security > Accessibility). This is required for global hotkey detection.

## Configuration

Click the menu bar icon or open Preferences (`Cmd+,`) to configure:

| Setting | Options |
|---------|---------|
| Hotkey | Any modifier key, F1-F12, Escape, Space, Tab, Delete |
| Style | Classic Dot, Spotlight, Glowing Halo, Crosshair |
| Color | Red, Green, Blue, Amber, White |
| Size | 10pt - 60pt |

Each style has additional settings in the **Styles** tab (trail length, dim opacity, pulse speed, line thickness).

## Requirements

- macOS 14 (Sonoma) or later
- Accessibility permission

## License

[MIT](LICENSE)
