# LaserTool — macOS Screen Laser Pointer

**Date**: 2026-04-10
**Status**: v1 Design
**Platform**: macOS 14+ Sonoma (native Swift + AppKit overlay, SwiftUI preferences)

## Overview

A macOS menu bar app that provides a screen-overlay laser pointer for use during screen sharing. Hold a hotkey (double-click + hold activation gesture) to display a laser pointer that follows the cursor. Works with any screen-sharing tool (Zoom, Meet, Teams, etc.) because it draws directly on the screen as a transparent overlay.

## Architecture

Four layers:

### 1. App Shell
- `NSApplication` with `LSUIElement = true` (no dock icon)
- `NSStatusItem` for menu bar presence
- Entry point and lifecycle management

### 2. Overlay Window
- Borderless, transparent `NSWindow` at `.screenSaver` window level
- Spans all connected screens
- `ignoresMouseEvents = true` by default, flips to `false` when right-click context menu is needed
- Hosts a custom `NSView` subclass with Core Animation layers for rendering
- `hasShadow = false`, `isOpaque = false` to minimize compositing cost

### 3. Input Engine
- Global hotkey detection via `CGEvent` tap at `kCGAnnotatedSessionEventTap`
- Requires Accessibility permission (prompted on first launch with explanation dialog)
- Mouse position tracking via `CGEvent` tap for `mouseMoved` events while laser is active

### 4. Preferences
- SwiftUI window for all settings
- Data persisted via `UserDefaults`
- Accessible from menu bar dropdown

```
┌──────────────────────────────────────┐
│           Menu Bar Icon              │
│  (NSStatusItem + SwiftUI popover)    │
├──────────────────────────────────────┤
│         Input Engine                 │
│  (CGEvent tap + gesture detection)   │
├──────────────────────────────────────┤
│       Laser Renderer                 │
│  (4 styles, Core Animation layers)   │
├──────────────────────────────────────┤
│       Overlay Window (NSWindow)      │
│     Transparent, full-screen,        │
│     all monitors                     │
├──────────────────────────────────────┤
│    Preferences (SwiftUI window)      │
│    UserDefaults persistence          │
└──────────────────────────────────────┘
```

## Activation Gesture

Double-click + hold on a configurable hotkey:

1. First key-down → start a 300ms timer window
2. Key-up + second key-down within the window → laser activates
3. Key-up after activation → laser deactivates
4. Single press with no second press → ignored (prevents accidental triggers)

**Default hotkey**: Right Control key (rarely used, unlikely to conflict). Fully configurable in preferences.

## Laser Pointer Styles

All rendered via Core Animation layers on the overlay view. Color and base size are shared across all styles and configurable.

### Classic Laser Dot
- `CAShapeLayer` circle with `CAShadowPath` for outer glow
- **Trail**: Ring buffer of the last 30 mouse positions. Each renders as a dot with decreasing opacity and size, creating a comet-tail effect.
- Trail length and fade speed configurable in preferences
- Default color: red

### Spotlight / Dimming
- Full-screen semi-transparent black `CALayer` with a `CAShapeLayer` mask creating a circular cut-out around the cursor
- Dim opacity configurable: 40-80% (default: 60%)
- Cut-out circle diameter matches the configured laser size

### Glowing Halo
- `CAShapeLayer` ring (no fill) with `CABasicAnimation` pulsing opacity (0.6 → 1.0) and scale (0.95 → 1.05)
- Pulse speed configurable (default: 1.2s cycle)
- Default color: amber/orange

### Crosshair
- Two `CAShapeLayer` lines (horizontal + vertical) extending 40pt from center + center dot
- Line thickness configurable (default: 1.5pt)
- Default color: green

## Rendering

- `CADisplayLink` (macOS 14+) drives the render loop at screen refresh rate
- Only redraws when cursor moves or animations are active (halo pulse)
- All drawing happens on Core Animation layers — no manual `draw(_ rect:)` needed

## Menu Bar

`NSStatusItem` with a small laser dot icon (filled when laser is active, outline when inactive).

**Dropdown menu**:
- Style picker (radio group: Classic Dot / Spotlight / Halo / Crosshair)
- Color picker (preset swatches: red, green, blue, amber, white, custom)
- Size slider
- Separator
- Preferences...
- Quit LaserTool

## Right-Click Context Menu

When the laser is active, right-clicking shows a context menu on the overlay:
- Quick style switch (all 4 styles)
- Quick color switch (preset colors)
- Open Preferences

Implementation: The `CGEvent` tap detects right-click events globally. When a right-click is detected while the laser is active, temporarily set `ignoresMouseEvents = false` on the overlay, programmatically trigger the `NSMenu` at the cursor location, then restore `ignoresMouseEvents = true` after the menu closes.

## Preferences Window (SwiftUI)

| Section | Controls |
|---------|----------|
| **Hotkey** | "Press to record" button using a key-recording view |
| **Style** | Visual picker showing icons for all 4 styles |
| **Color** | `ColorPicker` + preset swatches |
| **Size** | Slider (10pt - 60pt, default 24pt) |
| **Classic Dot Trail** | Toggle on/off, trail length slider (10-50 points), fade speed slider |
| **Spotlight** | Dim opacity slider (40-80%) |
| **Halo** | Pulse speed slider (0.5s - 3s) |
| **Crosshair** | Line thickness slider (0.5pt - 4pt) |
| **General** | Launch at login toggle |

All values persisted via `UserDefaults` with sensible defaults.

## Permissions

- **Accessibility**: Required for `CGEvent` tap (global hotkey monitoring). Prompted on first launch with a clear explanation: "LaserTool needs Accessibility access to detect your hotkey globally."
- **Screen Recording**: Not required (overlay draws on top, no screen capture needed).

## Project Structure

```
LaserTool/
├── LaserTool.xcodeproj
├── LaserTool/
│   ├── App/
│   │   ├── AppDelegate.swift          # NSApplication lifecycle, status item
│   │   └── LaserToolApp.swift         # @main entry point
│   ├── Overlay/
│   │   ├── OverlayWindowController.swift  # Creates/manages overlay windows
│   │   ├── OverlayView.swift              # NSView hosting CA layers
│   │   └── Renderers/
│   │       ├── LaserRenderer.swift        # Protocol for all renderers
│   │       ├── ClassicDotRenderer.swift   # Dot + trail
│   │       ├── SpotlightRenderer.swift    # Dimming + cutout
│   │       ├── HaloRenderer.swift         # Pulsing ring
│   │       └── CrosshairRenderer.swift    # Crosshair lines
│   ├── Input/
│   │   ├── HotkeyManager.swift        # CGEvent tap setup/teardown
│   │   ├── GestureDetector.swift      # Double-click + hold logic
│   │   └── MouseTracker.swift         # Cursor position tracking
│   ├── Preferences/
│   │   ├── PreferencesView.swift      # SwiftUI root view
│   │   ├── HotkeyRecorderView.swift   # Key recording widget
│   │   ├── StylePickerView.swift      # Visual style selector
│   │   └── PreferencesManager.swift   # UserDefaults wrapper
│   ├── Menu/
│   │   ├── StatusBarController.swift  # NSStatusItem management
│   │   └── ContextMenuController.swift # Right-click menu
│   └── Resources/
│       ├── Assets.xcassets
│       └── Info.plist
└── docs/
```

## Future (Out of Scope for v1)

- **Annotations**: Freehand drawing on the overlay (configurable fade vs persist). Deferred to v2.
- **Shapes**: Arrows, rectangles, text annotations.
- **Multi-monitor awareness**: Style that highlights which monitor is active.
- **Preset profiles**: Save/load combinations of style + color + size.
