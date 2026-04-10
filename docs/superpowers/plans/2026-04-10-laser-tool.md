# LaserTool Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a macOS menu bar app that provides a screen-overlay laser pointer with 4 visual styles, activated by a double-click-and-hold hotkey gesture.

**Architecture:** Swift Package Manager executable. AppKit `NSWindow` overlay at `.screenSaver` level for rendering via Core Animation layers. `CGEvent` tap for global hotkey/mouse detection. SwiftUI for the preferences window. No dock icon (`NSApp.setActivationPolicy(.accessory)`).

**Tech Stack:** Swift 5.9+, macOS 14+, AppKit, SwiftUI, Core Animation, CGEvent API, XCTest

**Spec:** `docs/superpowers/specs/2026-04-10-laser-tool-design.md`

---

## File Structure

```
LaserTool/
├── Package.swift                              # SPM package definition
├── Sources/LaserTool/
│   ├── main.swift                             # Entry point: NSApplication setup
│   ├── AppDelegate.swift                      # Lifecycle, wires all components
│   ├── Preferences/
│   │   └── PreferencesManager.swift           # UserDefaults wrapper, all settings
│   ├── Overlay/
│   │   ├── OverlayWindowController.swift      # Creates/manages transparent overlay windows
│   │   ├── OverlayView.swift                  # NSView hosting Core Animation layers
│   │   └── Renderers/
│   │       ├── LaserRenderer.swift            # Protocol + LaserStyle enum
│   │       ├── ClassicDotRenderer.swift       # Dot + glow + trail
│   │       ├── SpotlightRenderer.swift        # Dim screen + cutout
│   │       ├── HaloRenderer.swift             # Pulsing ring
│   │       └── CrosshairRenderer.swift        # Crosshair lines + center dot
│   ├── Input/
│   │   ├── GestureDetector.swift              # Double-click + hold state machine
│   │   ├── HotkeyManager.swift                # CGEvent tap setup/teardown
│   │   └── MouseTracker.swift                 # Cursor position forwarding
│   ├── Menu/
│   │   ├── StatusBarController.swift          # NSStatusItem + dropdown menu
│   │   └── ContextMenuController.swift        # Right-click menu on overlay
│   └── UI/
│       ├── PreferencesView.swift              # SwiftUI preferences window
│       ├── StylePickerView.swift              # Visual style selector
│       └── HotkeyRecorderView.swift           # Key recording NSView wrapper
├── Tests/LaserToolTests/
│   ├── PreferencesManagerTests.swift
│   ├── GestureDetectorTests.swift
│   └── RingBufferTests.swift
└── docs/
```

---

### Task 1: Project Scaffolding + App Shell

**Files:**
- Create: `Package.swift`
- Create: `Sources/LaserTool/main.swift`
- Create: `Sources/LaserTool/AppDelegate.swift`

- [ ] **Step 1: Create Package.swift**

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LaserTool",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "LaserTool",
            path: "Sources/LaserTool",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("SwiftUI"),
                .linkedFramework("QuartzCore"),
            ]
        ),
        .testTarget(
            name: "LaserToolTests",
            dependencies: ["LaserTool"],
            path: "Tests/LaserToolTests"
        ),
    ]
)
```

- [ ] **Step 2: Create main.swift**

```swift
import AppKit

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
```

- [ ] **Step 3: Create AppDelegate.swift**

```swift
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSLog("LaserTool launched")
    }

    func applicationWillTerminate(_ notification: Notification) {
        NSLog("LaserTool terminating")
    }
}
```

- [ ] **Step 4: Create empty test file so the test target compiles**

Create `Tests/LaserToolTests/PlaceholderTest.swift`:

```swift
import XCTest

final class PlaceholderTest: XCTestCase {
    func testLaunch() {
        XCTAssertTrue(true)
    }
}
```

- [ ] **Step 5: Build and verify**

Run: `cd /Users/vijay/IdeaProjects/laserTool && swift build 2>&1`
Expected: `Build complete!`

Run: `swift test 2>&1`
Expected: `Test Suite 'All tests' passed`

- [ ] **Step 6: Commit**

```bash
git init
echo ".build/\n.swiftpm/\n.superpowers/\n*.xcodeproj/\nxcuserdata/\nDerivedData/" > .gitignore
git add Package.swift Sources/ Tests/ .gitignore docs/
git commit -m "feat: project scaffolding with SPM executable and app shell"
```

---

### Task 2: PreferencesManager

**Files:**
- Create: `Sources/LaserTool/Preferences/PreferencesManager.swift`
- Create: `Tests/LaserToolTests/PreferencesManagerTests.swift`

- [ ] **Step 1: Write failing tests**

Create `Tests/LaserToolTests/PreferencesManagerTests.swift`:

```swift
import XCTest
@testable import LaserTool

final class PreferencesManagerTests: XCTestCase {
    var prefs: PreferencesManager!

    override func setUp() {
        super.setUp()
        prefs = PreferencesManager(defaults: UserDefaults(suiteName: "test-\(UUID().uuidString)")!)
    }

    func testDefaultStyle() {
        XCTAssertEqual(prefs.laserStyle, .classicDot)
    }

    func testDefaultColor() {
        XCTAssertEqual(prefs.laserColor, .red)
    }

    func testDefaultSize() {
        XCTAssertEqual(prefs.laserSize, 24.0, accuracy: 0.01)
    }

    func testDefaultTrailEnabled() {
        XCTAssertTrue(prefs.trailEnabled)
    }

    func testDefaultTrailLength() {
        XCTAssertEqual(prefs.trailLength, 30)
    }

    func testDefaultSpotlightOpacity() {
        XCTAssertEqual(prefs.spotlightDimOpacity, 0.6, accuracy: 0.01)
    }

    func testDefaultHaloPulseSpeed() {
        XCTAssertEqual(prefs.haloPulseSpeed, 1.2, accuracy: 0.01)
    }

    func testDefaultCrosshairThickness() {
        XCTAssertEqual(prefs.crosshairThickness, 1.5, accuracy: 0.01)
    }

    func testDefaultHotkeyCode() {
        // Right Control key = keyCode 62
        XCTAssertEqual(prefs.hotkeyKeyCode, 62)
    }

    func testSetAndGetStyle() {
        prefs.laserStyle = .spotlight
        XCTAssertEqual(prefs.laserStyle, .spotlight)
    }

    func testSetAndGetSize() {
        prefs.laserSize = 40.0
        XCTAssertEqual(prefs.laserSize, 40.0, accuracy: 0.01)
    }

    func testSetAndGetColor() {
        prefs.laserColor = .green
        XCTAssertEqual(prefs.laserColor, .green)
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `swift test 2>&1 | tail -20`
Expected: Compilation error — `PreferencesManager` not defined.

- [ ] **Step 3: Implement PreferencesManager**

Create `Sources/LaserTool/Preferences/PreferencesManager.swift`:

```swift
import AppKit

enum LaserStyle: String, CaseIterable {
    case classicDot = "classicDot"
    case spotlight = "spotlight"
    case halo = "halo"
    case crosshair = "crosshair"
}

enum LaserColor: String, CaseIterable {
    case red, green, blue, amber, white

    var nsColor: NSColor {
        switch self {
        case .red: return NSColor(red: 1.0, green: 0.2, blue: 0.2, alpha: 1.0)
        case .green: return NSColor(red: 0.0, green: 1.0, blue: 0.53, alpha: 1.0)
        case .blue: return NSColor(red: 0.2, green: 0.6, blue: 1.0, alpha: 1.0)
        case .amber: return NSColor(red: 1.0, green: 0.66, blue: 0.0, alpha: 1.0)
        case .white: return NSColor.white
        }
    }
}

class PreferencesManager: ObservableObject {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    // MARK: - Style

    @Published var laserStyle: LaserStyle {
        get { LaserStyle(rawValue: defaults.string(forKey: "laserStyle") ?? "") ?? .classicDot }
        set { defaults.set(newValue.rawValue, forKey: "laserStyle"); objectWillChange.send() }
    }

    // MARK: - Color

    var laserColor: LaserColor {
        get { LaserColor(rawValue: defaults.string(forKey: "laserColor") ?? "") ?? .red }
        set { defaults.set(newValue.rawValue, forKey: "laserColor") }
    }

    // MARK: - Size

    var laserSize: CGFloat {
        get {
            let val = defaults.double(forKey: "laserSize")
            return val > 0 ? val : 24.0
        }
        set { defaults.set(newValue, forKey: "laserSize") }
    }

    // MARK: - Trail (Classic Dot)

    var trailEnabled: Bool {
        get {
            if defaults.object(forKey: "trailEnabled") == nil { return true }
            return defaults.bool(forKey: "trailEnabled")
        }
        set { defaults.set(newValue, forKey: "trailEnabled") }
    }

    var trailLength: Int {
        get {
            let val = defaults.integer(forKey: "trailLength")
            return val > 0 ? val : 30
        }
        set { defaults.set(newValue, forKey: "trailLength") }
    }

    var trailFadeSpeed: Double {
        get {
            let val = defaults.double(forKey: "trailFadeSpeed")
            return val > 0 ? val : 0.3
        }
        set { defaults.set(newValue, forKey: "trailFadeSpeed") }
    }

    // MARK: - Spotlight

    var spotlightDimOpacity: Double {
        get {
            let val = defaults.double(forKey: "spotlightDimOpacity")
            return val > 0 ? val : 0.6
        }
        set { defaults.set(newValue, forKey: "spotlightDimOpacity") }
    }

    // MARK: - Halo

    var haloPulseSpeed: Double {
        get {
            let val = defaults.double(forKey: "haloPulseSpeed")
            return val > 0 ? val : 1.2
        }
        set { defaults.set(newValue, forKey: "haloPulseSpeed") }
    }

    // MARK: - Crosshair

    var crosshairThickness: CGFloat {
        get {
            let val = defaults.double(forKey: "crosshairThickness")
            return val > 0 ? val : 1.5
        }
        set { defaults.set(newValue, forKey: "crosshairThickness") }
    }

    // MARK: - Hotkey

    var hotkeyKeyCode: UInt16 {
        get {
            if defaults.object(forKey: "hotkeyKeyCode") == nil { return 62 }
            return UInt16(defaults.integer(forKey: "hotkeyKeyCode"))
        }
        set { defaults.set(Int(newValue), forKey: "hotkeyKeyCode") }
    }

    // MARK: - Launch at Login

    var launchAtLogin: Bool {
        get { defaults.bool(forKey: "launchAtLogin") }
        set { defaults.set(newValue, forKey: "launchAtLogin") }
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `swift test --filter PreferencesManagerTests 2>&1`
Expected: All tests pass.

- [ ] **Step 5: Commit**

```bash
git add Sources/LaserTool/Preferences/ Tests/LaserToolTests/PreferencesManagerTests.swift
git commit -m "feat: add PreferencesManager with UserDefaults persistence and tests"
```

---

### Task 3: Overlay Window

**Files:**
- Create: `Sources/LaserTool/Overlay/OverlayWindowController.swift`
- Create: `Sources/LaserTool/Overlay/OverlayView.swift`

- [ ] **Step 1: Create OverlayView**

Create `Sources/LaserTool/Overlay/OverlayView.swift`:

```swift
import AppKit
import QuartzCore

class OverlayView: NSView {
    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) not supported")
    }

    override var isFlipped: Bool { true }
}
```

- [ ] **Step 2: Create OverlayWindowController**

Create `Sources/LaserTool/Overlay/OverlayWindowController.swift`:

```swift
import AppKit

class OverlayWindowController {
    private(set) var windows: [NSWindow] = []
    private(set) var overlayViews: [OverlayView] = []

    func createOverlays() {
        tearDown()
        for screen in NSScreen.screens {
            let window = NSWindow(
                contentRect: screen.frame,
                styleMask: .borderless,
                backing: .buffered,
                defer: false
            )
            window.level = .screenSaver
            window.isOpaque = false
            window.hasShadow = false
            window.backgroundColor = .clear
            window.ignoresMouseEvents = true
            window.collectionBehavior = [.canJoinAllSpaces, .stationary]

            let overlayView = OverlayView(frame: screen.frame)
            window.contentView = overlayView

            window.orderFrontRegardless()

            windows.append(window)
            overlayViews.append(overlayView)
        }
    }

    func tearDown() {
        for window in windows {
            window.orderOut(nil)
        }
        windows.removeAll()
        overlayViews.removeAll()
    }

    /// Returns the overlay view whose window contains the given screen point.
    func overlayView(for point: NSPoint) -> OverlayView? {
        for (i, window) in windows.enumerated() {
            if NSPointInRect(point, window.frame) {
                return overlayViews[i]
            }
        }
        return overlayViews.first
    }

    /// Converts a screen-space point to the coordinate system of the overlay view.
    func convertToOverlay(_ screenPoint: NSPoint, in view: OverlayView) -> NSPoint {
        guard let window = view.window else { return screenPoint }
        let windowPoint = window.convertPoint(fromScreen: screenPoint)
        return view.convert(windowPoint, from: nil)
    }

    func setIgnoresMouseEvents(_ ignores: Bool) {
        for window in windows {
            window.ignoresMouseEvents = ignores
        }
    }
}
```

- [ ] **Step 3: Build and verify**

Run: `swift build 2>&1`
Expected: `Build complete!`

- [ ] **Step 4: Commit**

```bash
git add Sources/LaserTool/Overlay/
git commit -m "feat: add overlay window controller with transparent full-screen windows"
```

---

### Task 4: LaserRenderer Protocol + ClassicDotRenderer

**Files:**
- Create: `Sources/LaserTool/Overlay/Renderers/LaserRenderer.swift`
- Create: `Sources/LaserTool/Overlay/Renderers/ClassicDotRenderer.swift`
- Create: `Tests/LaserToolTests/RingBufferTests.swift`

- [ ] **Step 1: Write failing ring buffer tests**

Create `Tests/LaserToolTests/RingBufferTests.swift`:

```swift
import XCTest
@testable import LaserTool

final class RingBufferTests: XCTestCase {
    func testEmptyBuffer() {
        let buffer = RingBuffer<NSPoint>(capacity: 5)
        XCTAssertEqual(buffer.count, 0)
        XCTAssertTrue(buffer.allElements.isEmpty)
    }

    func testAppendWithinCapacity() {
        var buffer = RingBuffer<Int>(capacity: 3)
        buffer.append(1)
        buffer.append(2)
        XCTAssertEqual(buffer.count, 2)
        XCTAssertEqual(buffer.allElements, [1, 2])
    }

    func testAppendOverCapacity() {
        var buffer = RingBuffer<Int>(capacity: 3)
        buffer.append(1)
        buffer.append(2)
        buffer.append(3)
        buffer.append(4)
        XCTAssertEqual(buffer.count, 3)
        XCTAssertEqual(buffer.allElements, [2, 3, 4])
    }

    func testClear() {
        var buffer = RingBuffer<Int>(capacity: 3)
        buffer.append(1)
        buffer.append(2)
        buffer.clear()
        XCTAssertEqual(buffer.count, 0)
        XCTAssertTrue(buffer.allElements.isEmpty)
    }

    func testCapacityChange() {
        var buffer = RingBuffer<Int>(capacity: 5)
        buffer.append(1)
        buffer.append(2)
        buffer.append(3)
        buffer.capacity = 2
        // Should keep the 2 most recent
        XCTAssertEqual(buffer.count, 2)
        XCTAssertEqual(buffer.allElements, [2, 3])
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `swift test --filter RingBufferTests 2>&1 | tail -5`
Expected: Compilation error — `RingBuffer` not defined.

- [ ] **Step 3: Create LaserRenderer protocol**

Create `Sources/LaserTool/Overlay/Renderers/LaserRenderer.swift`:

```swift
import AppKit
import QuartzCore

struct RingBuffer<T> {
    private var buffer: [T] = []
    private var head: Int = 0
    private(set) var count: Int = 0
    var capacity: Int {
        didSet {
            if capacity < count {
                let elements = allElements
                buffer = Array(elements.suffix(capacity))
                head = 0
                count = buffer.count
            }
        }
    }

    init(capacity: Int) {
        self.capacity = capacity
        self.buffer = []
        self.buffer.reserveCapacity(capacity)
    }

    mutating func append(_ element: T) {
        if buffer.count < capacity {
            buffer.append(element)
            count = buffer.count
        } else {
            buffer[head] = element
            head = (head + 1) % capacity
            count = capacity
        }
    }

    /// Returns elements in insertion order (oldest first).
    var allElements: [T] {
        guard count > 0 else { return [] }
        if buffer.count < capacity {
            return buffer
        }
        return Array(buffer[head...]) + Array(buffer[..<head])
    }

    mutating func clear() {
        buffer.removeAll()
        head = 0
        count = 0
    }
}

protocol LaserRenderer: AnyObject {
    func activate(on layer: CALayer)
    func deactivate()
    func updatePosition(_ point: CGPoint)
    func updateAppearance(color: NSColor, size: CGFloat)
}
```

- [ ] **Step 4: Run ring buffer tests**

Run: `swift test --filter RingBufferTests 2>&1`
Expected: All tests pass.

- [ ] **Step 5: Create ClassicDotRenderer**

Create `Sources/LaserTool/Overlay/Renderers/ClassicDotRenderer.swift`:

```swift
import AppKit
import QuartzCore

class ClassicDotRenderer: LaserRenderer {
    private var dotLayer: CAShapeLayer?
    private var trailLayers: [CAShapeLayer] = []
    private var hostLayer: CALayer?
    private var trail = RingBuffer<CGPoint>(capacity: 30)

    var trailEnabled: Bool = true
    var trailLength: Int = 30 {
        didSet { trail.capacity = trailLength }
    }
    var trailFadeSpeed: Double = 0.3
    private var color: NSColor = .red
    private var size: CGFloat = 24.0

    func activate(on layer: CALayer) {
        hostLayer = layer
        trail.clear()

        let dot = CAShapeLayer()
        dot.path = CGPath(ellipseIn: CGRect(x: -size / 2, y: -size / 2, width: size, height: size), transform: nil)
        dot.fillColor = color.cgColor
        dot.shadowColor = color.cgColor
        dot.shadowRadius = size * 0.8
        dot.shadowOpacity = 0.7
        dot.shadowOffset = .zero

        layer.addSublayer(dot)
        dotLayer = dot
    }

    func deactivate() {
        dotLayer?.removeFromSuperlayer()
        dotLayer = nil
        for tl in trailLayers {
            tl.removeFromSuperlayer()
        }
        trailLayers.removeAll()
        trail.clear()
        hostLayer = nil
    }

    func updatePosition(_ point: CGPoint) {
        guard let hostLayer = hostLayer else { return }

        CATransaction.begin()
        CATransaction.setDisableActions(true)

        dotLayer?.position = point

        if trailEnabled {
            trail.append(point)
            syncTrailLayers(on: hostLayer)
        }

        CATransaction.commit()
    }

    func updateAppearance(color: NSColor, size: CGFloat) {
        self.color = color
        self.size = size
        guard let dot = dotLayer else { return }

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        dot.path = CGPath(ellipseIn: CGRect(x: -size / 2, y: -size / 2, width: size, height: size), transform: nil)
        dot.fillColor = color.cgColor
        dot.shadowColor = color.cgColor
        dot.shadowRadius = size * 0.8
        CATransaction.commit()
    }

    private func syncTrailLayers(on hostLayer: CALayer) {
        let points = trail.allElements
        let neededCount = max(0, points.count - 1) // exclude the head (that's the dot)

        // Add/remove trail layers to match
        while trailLayers.count < neededCount {
            let tl = CAShapeLayer()
            hostLayer.insertSublayer(tl, below: dotLayer)
            trailLayers.append(tl)
        }
        while trailLayers.count > neededCount {
            trailLayers.removeLast().removeFromSuperlayer()
        }

        // Update each trail dot
        for i in 0..<neededCount {
            let tl = trailLayers[i]
            let progress = CGFloat(i + 1) / CGFloat(points.count) // 0→1 from oldest to newest
            let trailSize = size * progress * 0.8
            let opacity = Float(progress * 0.6)

            tl.path = CGPath(ellipseIn: CGRect(x: -trailSize / 2, y: -trailSize / 2, width: trailSize, height: trailSize), transform: nil)
            tl.fillColor = color.withAlphaComponent(CGFloat(opacity)).cgColor
            tl.position = points[i]
            tl.shadowColor = color.cgColor
            tl.shadowRadius = trailSize * 0.5
            tl.shadowOpacity = opacity * 0.5
            tl.shadowOffset = .zero
        }
    }
}
```

- [ ] **Step 6: Build and verify**

Run: `swift build 2>&1`
Expected: `Build complete!`

- [ ] **Step 7: Commit**

```bash
git add Sources/LaserTool/Overlay/Renderers/ Tests/LaserToolTests/RingBufferTests.swift
git commit -m "feat: add LaserRenderer protocol, RingBuffer, and ClassicDotRenderer with trail"
```

---

### Task 5: Remaining Renderers (Spotlight, Halo, Crosshair)

**Files:**
- Create: `Sources/LaserTool/Overlay/Renderers/SpotlightRenderer.swift`
- Create: `Sources/LaserTool/Overlay/Renderers/HaloRenderer.swift`
- Create: `Sources/LaserTool/Overlay/Renderers/CrosshairRenderer.swift`

- [ ] **Step 1: Create SpotlightRenderer**

Create `Sources/LaserTool/Overlay/Renderers/SpotlightRenderer.swift`:

```swift
import AppKit
import QuartzCore

class SpotlightRenderer: LaserRenderer {
    private var dimLayer: CALayer?
    private var maskLayer: CAShapeLayer?
    private var hostLayer: CALayer?
    private var size: CGFloat = 24.0
    var dimOpacity: Double = 0.6

    func activate(on layer: CALayer) {
        hostLayer = layer

        let dim = CALayer()
        dim.frame = layer.bounds
        dim.backgroundColor = NSColor.black.withAlphaComponent(dimOpacity).cgColor

        let mask = CAShapeLayer()
        mask.frame = layer.bounds
        mask.fillRule = .evenOdd
        dim.mask = mask

        layer.addSublayer(dim)
        dimLayer = dim
        maskLayer = mask
    }

    func deactivate() {
        dimLayer?.removeFromSuperlayer()
        dimLayer = nil
        maskLayer = nil
        hostLayer = nil
    }

    func updatePosition(_ point: CGPoint) {
        guard let maskLayer = maskLayer, let hostLayer = hostLayer else { return }

        CATransaction.begin()
        CATransaction.setDisableActions(true)

        let fullRect = UIBezierPathCompat.rect(hostLayer.bounds)
        let spotlightRadius = size * 3
        let spotlightRect = CGRect(
            x: point.x - spotlightRadius,
            y: point.y - spotlightRadius,
            width: spotlightRadius * 2,
            height: spotlightRadius * 2
        )
        fullRect.append(UIBezierPathCompat.oval(in: spotlightRect))
        maskLayer.path = fullRect.cgPath

        CATransaction.commit()
    }

    func updateAppearance(color: NSColor, size: CGFloat) {
        self.size = size
        dimLayer?.backgroundColor = NSColor.black.withAlphaComponent(dimOpacity).cgColor
    }
}

/// Minimal cross-reference helper since NSBezierPath and CGPath bridging differs on macOS.
enum UIBezierPathCompat {
    static func rect(_ rect: CGRect) -> NSBezierPath {
        NSBezierPath(rect: rect)
    }

    static func oval(in rect: CGRect) -> NSBezierPath {
        NSBezierPath(ovalIn: rect)
    }
}

extension NSBezierPath {
    /// Convert NSBezierPath to CGPath.
    var cgPath: CGPath {
        let path = CGMutablePath()
        var points = [CGPoint](repeating: .zero, count: 3)
        for i in 0..<elementCount {
            let kind = element(at: i, associatedPoints: &points)
            switch kind {
            case .moveTo: path.move(to: points[0])
            case .lineTo: path.addLine(to: points[0])
            case .curveTo: path.addCurve(to: points[2], control1: points[0], control2: points[1])
            case .closePath: path.closeSubpath()
            case .cubicCurveTo: path.addCurve(to: points[2], control1: points[0], control2: points[1])
            case .quadraticCurveTo: path.addQuadCurve(to: points[1], control: points[0])
            @unknown default: break
            }
        }
        return path
    }
}
```

- [ ] **Step 2: Create HaloRenderer**

Create `Sources/LaserTool/Overlay/Renderers/HaloRenderer.swift`:

```swift
import AppKit
import QuartzCore

class HaloRenderer: LaserRenderer {
    private var ringLayer: CAShapeLayer?
    private var hostLayer: CALayer?
    private var color: NSColor = NSColor(red: 1.0, green: 0.66, blue: 0.0, alpha: 1.0)
    private var size: CGFloat = 24.0
    var pulseSpeed: Double = 1.2

    func activate(on layer: CALayer) {
        hostLayer = layer

        let ring = CAShapeLayer()
        let ringSize = size * 2
        ring.path = CGPath(ellipseIn: CGRect(x: -ringSize / 2, y: -ringSize / 2, width: ringSize, height: ringSize), transform: nil)
        ring.fillColor = nil
        ring.strokeColor = color.cgColor
        ring.lineWidth = 3.0
        ring.shadowColor = color.cgColor
        ring.shadowRadius = 10.0
        ring.shadowOpacity = 0.6
        ring.shadowOffset = .zero

        layer.addSublayer(ring)
        ringLayer = ring

        addPulseAnimation()
    }

    func deactivate() {
        ringLayer?.removeAllAnimations()
        ringLayer?.removeFromSuperlayer()
        ringLayer = nil
        hostLayer = nil
    }

    func updatePosition(_ point: CGPoint) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        ringLayer?.position = point
        CATransaction.commit()
    }

    func updateAppearance(color: NSColor, size: CGFloat) {
        self.color = color
        self.size = size
        guard let ring = ringLayer else { return }

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        let ringSize = size * 2
        ring.path = CGPath(ellipseIn: CGRect(x: -ringSize / 2, y: -ringSize / 2, width: ringSize, height: ringSize), transform: nil)
        ring.strokeColor = color.cgColor
        ring.shadowColor = color.cgColor
        CATransaction.commit()

        ring.removeAllAnimations()
        addPulseAnimation()
    }

    private func addPulseAnimation() {
        let opacityAnim = CABasicAnimation(keyPath: "opacity")
        opacityAnim.fromValue = 0.6
        opacityAnim.toValue = 1.0

        let scaleAnim = CABasicAnimation(keyPath: "transform.scale")
        scaleAnim.fromValue = 0.95
        scaleAnim.toValue = 1.05

        let group = CAAnimationGroup()
        group.animations = [opacityAnim, scaleAnim]
        group.duration = pulseSpeed
        group.autoreverses = true
        group.repeatCount = .infinity
        group.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

        ringLayer?.add(group, forKey: "pulse")
    }
}
```

- [ ] **Step 3: Create CrosshairRenderer**

Create `Sources/LaserTool/Overlay/Renderers/CrosshairRenderer.swift`:

```swift
import AppKit
import QuartzCore

class CrosshairRenderer: LaserRenderer {
    private var horizontalLine: CAShapeLayer?
    private var verticalLine: CAShapeLayer?
    private var centerDot: CAShapeLayer?
    private var containerLayer: CALayer?
    private var hostLayer: CALayer?
    private var color: NSColor = NSColor(red: 0.0, green: 1.0, blue: 0.53, alpha: 1.0)
    private var size: CGFloat = 24.0
    var lineThickness: CGFloat = 1.5

    func activate(on layer: CALayer) {
        hostLayer = layer

        let container = CALayer()
        layer.addSublayer(container)
        containerLayer = container

        let armLength: CGFloat = size * 1.7
        let lineColor = color.cgColor
        let glowColor = color.cgColor

        let hLine = CAShapeLayer()
        let hPath = CGMutablePath()
        hPath.move(to: CGPoint(x: -armLength, y: 0))
        hPath.addLine(to: CGPoint(x: armLength, y: 0))
        hLine.path = hPath
        hLine.strokeColor = lineColor
        hLine.lineWidth = lineThickness
        hLine.shadowColor = glowColor
        hLine.shadowRadius = 4
        hLine.shadowOpacity = 0.5
        hLine.shadowOffset = .zero
        container.addSublayer(hLine)
        horizontalLine = hLine

        let vLine = CAShapeLayer()
        let vPath = CGMutablePath()
        vPath.move(to: CGPoint(x: 0, y: -armLength))
        vPath.addLine(to: CGPoint(x: 0, y: armLength))
        vLine.path = vPath
        vLine.strokeColor = lineColor
        vLine.lineWidth = lineThickness
        vLine.shadowColor = glowColor
        vLine.shadowRadius = 4
        vLine.shadowOpacity = 0.5
        vLine.shadowOffset = .zero
        container.addSublayer(vLine)
        verticalLine = vLine

        let dot = CAShapeLayer()
        let dotSize: CGFloat = 4.0
        dot.path = CGPath(ellipseIn: CGRect(x: -dotSize / 2, y: -dotSize / 2, width: dotSize, height: dotSize), transform: nil)
        dot.fillColor = lineColor
        dot.shadowColor = glowColor
        dot.shadowRadius = 6
        dot.shadowOpacity = 0.8
        dot.shadowOffset = .zero
        container.addSublayer(dot)
        centerDot = dot
    }

    func deactivate() {
        containerLayer?.removeFromSuperlayer()
        containerLayer = nil
        horizontalLine = nil
        verticalLine = nil
        centerDot = nil
        hostLayer = nil
    }

    func updatePosition(_ point: CGPoint) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        containerLayer?.position = point
        CATransaction.commit()
    }

    func updateAppearance(color: NSColor, size: CGFloat) {
        self.color = color
        self.size = size
        // Rebuild layers is simplest for crosshair
        if let host = hostLayer {
            deactivate()
            activate(on: host)
        }
    }
}
```

- [ ] **Step 4: Build and verify**

Run: `swift build 2>&1`
Expected: `Build complete!`

- [ ] **Step 5: Commit**

```bash
git add Sources/LaserTool/Overlay/Renderers/
git commit -m "feat: add Spotlight, Halo, and Crosshair renderers"
```

---

### Task 6: GestureDetector (Double-Click + Hold State Machine)

**Files:**
- Create: `Sources/LaserTool/Input/GestureDetector.swift`
- Create: `Tests/LaserToolTests/GestureDetectorTests.swift`

- [ ] **Step 1: Write failing tests**

Create `Tests/LaserToolTests/GestureDetectorTests.swift`:

```swift
import XCTest
@testable import LaserTool

final class GestureDetectorTests: XCTestCase {
    var detector: GestureDetector!
    var activations: [Bool]!

    override func setUp() {
        super.setUp()
        activations = []
        detector = GestureDetector(doubleClickWindow: 0.3) { [unowned self] active in
            self.activations.append(active)
        }
    }

    func testSinglePressDoesNotActivate() {
        detector.keyDown()
        detector.keyUp()
        // Wait past the double-click window
        RunLoop.current.run(until: Date().addingTimeInterval(0.4))
        XCTAssertTrue(activations.isEmpty)
    }

    func testDoubleClickAndHoldActivates() {
        detector.keyDown()
        detector.keyUp()
        // Second press within window
        detector.keyDown()
        XCTAssertEqual(activations, [true])
    }

    func testReleaseAfterActivationDeactivates() {
        detector.keyDown()
        detector.keyUp()
        detector.keyDown()
        XCTAssertEqual(activations, [true])
        detector.keyUp()
        XCTAssertEqual(activations, [true, false])
    }

    func testDoubleClickTooSlowDoesNotActivate() {
        detector.keyDown()
        detector.keyUp()
        // Wait past window
        RunLoop.current.run(until: Date().addingTimeInterval(0.4))
        detector.keyDown()
        detector.keyUp()
        // Should not have activated — the second press starts a new first-press
        XCTAssertTrue(activations.isEmpty)
    }

    func testRepeatedActivationCycles() {
        // First activation
        detector.keyDown()
        detector.keyUp()
        detector.keyDown()
        XCTAssertEqual(activations, [true])
        detector.keyUp()
        XCTAssertEqual(activations, [true, false])

        // Wait, then second activation
        RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        detector.keyDown()
        detector.keyUp()
        detector.keyDown()
        XCTAssertEqual(activations, [true, false, true])
        detector.keyUp()
        XCTAssertEqual(activations, [true, false, true, false])
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `swift test --filter GestureDetectorTests 2>&1 | tail -5`
Expected: Compilation error — `GestureDetector` not defined.

- [ ] **Step 3: Implement GestureDetector**

Create `Sources/LaserTool/Input/GestureDetector.swift`:

```swift
import Foundation

class GestureDetector {
    enum State {
        case idle
        case waitingForSecondPress
        case active
    }

    private(set) var state: State = .idle
    private let doubleClickWindow: TimeInterval
    private let onStateChange: (Bool) -> Void
    private var firstPressTime: Date?
    private var windowTimer: Timer?

    init(doubleClickWindow: TimeInterval = 0.3, onStateChange: @escaping (Bool) -> Void) {
        self.doubleClickWindow = doubleClickWindow
        self.onStateChange = onStateChange
    }

    func keyDown() {
        switch state {
        case .idle:
            firstPressTime = Date()
            state = .waitingForSecondPress

        case .waitingForSecondPress:
            // Second press within window — activate
            windowTimer?.invalidate()
            windowTimer = nil
            state = .active
            onStateChange(true)

        case .active:
            // Already active (key repeat) — ignore
            break
        }
    }

    func keyUp() {
        switch state {
        case .idle:
            break

        case .waitingForSecondPress:
            // Released after first press — start timer to reset if no second press comes
            windowTimer?.invalidate()
            windowTimer = Timer.scheduledTimer(withTimeInterval: doubleClickWindow, repeats: false) { [weak self] _ in
                self?.state = .idle
                self?.firstPressTime = nil
                self?.windowTimer = nil
            }

        case .active:
            state = .idle
            firstPressTime = nil
            onStateChange(false)
        }
    }

    func reset() {
        windowTimer?.invalidate()
        windowTimer = nil
        if state == .active {
            onStateChange(false)
        }
        state = .idle
        firstPressTime = nil
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `swift test --filter GestureDetectorTests 2>&1`
Expected: All tests pass.

- [ ] **Step 5: Commit**

```bash
git add Sources/LaserTool/Input/GestureDetector.swift Tests/LaserToolTests/GestureDetectorTests.swift
git commit -m "feat: add GestureDetector with double-click-and-hold state machine and tests"
```

---

### Task 7: HotkeyManager + MouseTracker

**Files:**
- Create: `Sources/LaserTool/Input/HotkeyManager.swift`
- Create: `Sources/LaserTool/Input/MouseTracker.swift`

- [ ] **Step 1: Create HotkeyManager**

Create `Sources/LaserTool/Input/HotkeyManager.swift`:

```swift
import AppKit
import CoreGraphics

class HotkeyManager {
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    var onKeyDown: ((UInt16) -> Void)?
    var onKeyUp: ((UInt16) -> Void)?
    var onRightClick: ((CGPoint) -> Void)?
    var onMouseMoved: ((CGPoint) -> Void)?
    var trackedKeyCode: UInt16 = 62 // Right Control

    func start() -> Bool {
        let eventMask: CGEventMask = (
            (1 << CGEventType.keyDown.rawValue) |
            (1 << CGEventType.keyUp.rawValue) |
            (1 << CGEventType.flagsChanged.rawValue) |
            (1 << CGEventType.mouseMoved.rawValue) |
            (1 << CGEventType.leftMouseDragged.rawValue) |
            (1 << CGEventType.rightMouseDown.rawValue)
        )

        guard let tap = CGEvent.tapCreate(
            tap: .cgAnnotatedSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: eventMask,
            callback: hotkeyCallback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            NSLog("LaserTool: Failed to create event tap. Check Accessibility permissions.")
            return false
        }

        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        return true
    }

    func stop() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
        }
        eventTap = nil
        runLoopSource = nil
    }

    fileprivate func handleEvent(_ type: CGEventType, event: CGEvent) {
        switch type {
        case .keyDown:
            let keyCode = UInt16(event.getIntegerValueField(.keyboardEventKeycode))
            if keyCode == trackedKeyCode {
                // Ignore key repeats
                if event.getIntegerValueField(.keyboardEventAutorepeat) == 0 {
                    onKeyDown?(keyCode)
                }
            }

        case .keyUp:
            let keyCode = UInt16(event.getIntegerValueField(.keyboardEventKeycode))
            if keyCode == trackedKeyCode {
                onKeyUp?(keyCode)
            }

        case .flagsChanged:
            // For modifier keys (like Right Control), flagsChanged fires instead of keyDown/keyUp.
            let keyCode = UInt16(event.getIntegerValueField(.keyboardEventKeycode))
            if keyCode == trackedKeyCode {
                let flags = event.flags
                // Check if the modifier is pressed or released based on flags
                let isPressed = isModifierPressed(keyCode: keyCode, flags: flags)
                if isPressed {
                    onKeyDown?(keyCode)
                } else {
                    onKeyUp?(keyCode)
                }
            }

        case .mouseMoved, .leftMouseDragged:
            let location = event.location
            onMouseMoved?(location)

        case .rightMouseDown:
            let location = event.location
            onRightClick?(location)

        default:
            break
        }
    }

    private func isModifierPressed(keyCode: UInt16, flags: CGEventFlags) -> Bool {
        switch keyCode {
        case 62, 59: // Right/Left Control
            return flags.contains(.maskControl)
        case 58, 61: // Left/Right Option
            return flags.contains(.maskAlternate)
        case 56, 60: // Left/Right Shift
            return flags.contains(.maskShift)
        case 55, 54: // Left/Right Command
            return flags.contains(.maskCommand)
        default:
            return false
        }
    }

    static func checkAccessibilityPermission() -> Bool {
        let trusted = AXIsProcessTrustedWithOptions(
            [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
        )
        return trusted
    }
}

private func hotkeyCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    userInfo: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    guard let userInfo = userInfo else { return Unmanaged.passRetained(event) }
    let manager = Unmanaged<HotkeyManager>.fromOpaque(userInfo).takeUnretainedValue()

    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
        // Re-enable the tap
        if let tap = manager.eventTap {
            CGEvent.tapEnable(tap: tap, enable: true)
        }
        return Unmanaged.passRetained(event)
    }

    manager.handleEvent(type, event: event)
    return Unmanaged.passRetained(event)
}
```

- [ ] **Step 2: Create MouseTracker**

Create `Sources/LaserTool/Input/MouseTracker.swift`:

```swift
import AppKit

class MouseTracker {
    var onPositionChanged: ((NSPoint) -> Void)?

    /// Called by HotkeyManager when mouse moves. Converts CG screen coordinates
    /// (origin bottom-left) to the position needed by the overlay.
    func handleMouseMoved(_ cgPoint: CGPoint) {
        // CGEvent uses bottom-left origin. NSScreen also uses bottom-left.
        // The overlay window frame matches the screen frame, so we can convert directly.
        let nsPoint = NSPoint(x: cgPoint.x, y: cgPoint.y)
        onPositionChanged?(nsPoint)
    }
}
```

- [ ] **Step 3: Build and verify**

Run: `swift build 2>&1`
Expected: `Build complete!`

- [ ] **Step 4: Commit**

```bash
git add Sources/LaserTool/Input/
git commit -m "feat: add HotkeyManager with CGEvent tap and MouseTracker"
```

---

### Task 8: StatusBarController + ContextMenuController

**Files:**
- Create: `Sources/LaserTool/Menu/StatusBarController.swift`
- Create: `Sources/LaserTool/Menu/ContextMenuController.swift`

- [ ] **Step 1: Create StatusBarController**

Create `Sources/LaserTool/Menu/StatusBarController.swift`:

```swift
import AppKit
import SwiftUI

class StatusBarController {
    private var statusItem: NSStatusItem?
    var onStyleChanged: ((LaserStyle) -> Void)?
    var onColorChanged: ((LaserColor) -> Void)?
    var onPreferencesRequested: (() -> Void)?
    var onQuit: (() -> Void)?
    private var currentStyle: LaserStyle = .classicDot

    func setup() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        updateIcon(active: false)
        buildMenu()
    }

    func updateIcon(active: Bool) {
        guard let button = statusItem?.button else { return }
        if let image = NSImage(systemSymbolName: active ? "circle.fill" : "circle",
                               accessibilityDescription: "LaserTool") {
            image.isTemplate = true
            button.image = image
        }
    }

    private func buildMenu() {
        let menu = NSMenu()

        // Style submenu
        let styleItem = NSMenuItem(title: "Style", action: nil, keyEquivalent: "")
        let styleMenu = NSMenu()
        for style in LaserStyle.allCases {
            let item = NSMenuItem(title: style.displayName, action: #selector(styleSelected(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = style.rawValue
            if style == currentStyle { item.state = .on }
            styleMenu.addItem(item)
        }
        styleItem.submenu = styleMenu
        menu.addItem(styleItem)

        // Color submenu
        let colorItem = NSMenuItem(title: "Color", action: nil, keyEquivalent: "")
        let colorMenu = NSMenu()
        for color in LaserColor.allCases {
            let item = NSMenuItem(title: color.rawValue.capitalized, action: #selector(colorSelected(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = color.rawValue
            colorMenu.addItem(item)
        }
        colorItem.submenu = colorMenu
        menu.addItem(colorItem)

        menu.addItem(.separator())

        let prefsItem = NSMenuItem(title: "Preferences...", action: #selector(openPreferences), keyEquivalent: ",")
        prefsItem.target = self
        menu.addItem(prefsItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Quit LaserTool", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem?.menu = menu
    }

    @objc private func styleSelected(_ sender: NSMenuItem) {
        guard let rawValue = sender.representedObject as? String,
              let style = LaserStyle(rawValue: rawValue) else { return }
        currentStyle = style
        onStyleChanged?(style)
        buildMenu() // Refresh checkmarks
    }

    @objc private func colorSelected(_ sender: NSMenuItem) {
        guard let rawValue = sender.representedObject as? String,
              let color = LaserColor(rawValue: rawValue) else { return }
        onColorChanged?(color)
    }

    @objc private func openPreferences() {
        onPreferencesRequested?()
    }

    @objc private func quit() {
        onQuit?()
    }
}

extension LaserStyle {
    var displayName: String {
        switch self {
        case .classicDot: return "Classic Dot"
        case .spotlight: return "Spotlight"
        case .halo: return "Glowing Halo"
        case .crosshair: return "Crosshair"
        }
    }
}
```

- [ ] **Step 2: Create ContextMenuController**

Create `Sources/LaserTool/Menu/ContextMenuController.swift`:

```swift
import AppKit

class ContextMenuController {
    var onStyleChanged: ((LaserStyle) -> Void)?
    var onColorChanged: ((LaserColor) -> Void)?
    var onPreferencesRequested: (() -> Void)?

    func showMenu(at screenPoint: NSPoint, on overlayController: OverlayWindowController) {
        let menu = NSMenu()

        // Style items
        for style in LaserStyle.allCases {
            let item = NSMenuItem(title: style.displayName, action: #selector(styleSelected(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = style.rawValue
            menu.addItem(item)
        }

        menu.addItem(.separator())

        // Color items
        for color in LaserColor.allCases {
            let item = NSMenuItem(title: color.rawValue.capitalized, action: #selector(colorSelected(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = color.rawValue
            menu.addItem(item)
        }

        menu.addItem(.separator())

        let prefsItem = NSMenuItem(title: "Preferences...", action: #selector(openPreferences), keyEquivalent: "")
        prefsItem.target = self
        menu.addItem(prefsItem)

        // Temporarily allow mouse events so the menu works
        overlayController.setIgnoresMouseEvents(false)

        // Find the right window and show menu
        if let view = overlayController.overlayView(for: screenPoint),
           let window = view.window {
            let windowPoint = window.convertPoint(fromScreen: screenPoint)
            menu.popUp(positioning: nil, at: windowPoint, in: view)
        }

        // Restore after menu closes
        overlayController.setIgnoresMouseEvents(true)
    }

    @objc private func styleSelected(_ sender: NSMenuItem) {
        guard let rawValue = sender.representedObject as? String,
              let style = LaserStyle(rawValue: rawValue) else { return }
        onStyleChanged?(style)
    }

    @objc private func colorSelected(_ sender: NSMenuItem) {
        guard let rawValue = sender.representedObject as? String,
              let color = LaserColor(rawValue: rawValue) else { return }
        onColorChanged?(color)
    }

    @objc private func openPreferences() {
        onPreferencesRequested?()
    }
}
```

- [ ] **Step 3: Build and verify**

Run: `swift build 2>&1`
Expected: `Build complete!`

- [ ] **Step 4: Commit**

```bash
git add Sources/LaserTool/Menu/
git commit -m "feat: add StatusBarController and ContextMenuController"
```

---

### Task 9: Preferences Window (SwiftUI)

**Files:**
- Create: `Sources/LaserTool/UI/PreferencesView.swift`
- Create: `Sources/LaserTool/UI/StylePickerView.swift`
- Create: `Sources/LaserTool/UI/HotkeyRecorderView.swift`

- [ ] **Step 1: Create StylePickerView**

Create `Sources/LaserTool/UI/StylePickerView.swift`:

```swift
import SwiftUI

struct StylePickerView: View {
    @Binding var selectedStyle: LaserStyle

    var body: some View {
        HStack(spacing: 12) {
            ForEach(LaserStyle.allCases, id: \.self) { style in
                Button(action: { selectedStyle = style }) {
                    VStack(spacing: 6) {
                        styleIcon(style)
                            .frame(width: 40, height: 40)
                        Text(style.displayName)
                            .font(.caption)
                    }
                    .padding(8)
                    .background(selectedStyle == style ? Color.accentColor.opacity(0.2) : Color.clear)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(selectedStyle == style ? Color.accentColor : Color.gray.opacity(0.3), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private func styleIcon(_ style: LaserStyle) -> some View {
        switch style {
        case .classicDot:
            Circle()
                .fill(Color.red)
                .frame(width: 16, height: 16)
                .shadow(color: .red.opacity(0.6), radius: 6)
        case .spotlight:
            ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.black.opacity(0.6))
                    .frame(width: 32, height: 32)
                Circle()
                    .fill(Color.clear)
                    .frame(width: 14, height: 14)
                    .overlay(Circle().stroke(Color.white.opacity(0.8), lineWidth: 1))
            }
        case .halo:
            Circle()
                .stroke(Color.orange, lineWidth: 2)
                .frame(width: 20, height: 20)
                .shadow(color: .orange.opacity(0.5), radius: 4)
        case .crosshair:
            ZStack {
                Rectangle().fill(Color.green).frame(width: 1.5, height: 24)
                Rectangle().fill(Color.green).frame(width: 24, height: 1.5)
                Circle().fill(Color.green).frame(width: 4, height: 4)
            }
        }
    }
}
```

- [ ] **Step 2: Create HotkeyRecorderView**

Create `Sources/LaserTool/UI/HotkeyRecorderView.swift`:

```swift
import SwiftUI
import AppKit

struct HotkeyRecorderView: View {
    @Binding var keyCode: UInt16
    @State private var isRecording = false

    var body: some View {
        Button(action: { isRecording.toggle() }) {
            Text(isRecording ? "Press a key..." : keyName(for: keyCode))
                .frame(minWidth: 120)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isRecording ? Color.accentColor.opacity(0.2) : Color.gray.opacity(0.1))
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isRecording ? Color.accentColor : Color.gray.opacity(0.3), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .background(
            KeyRecorderRepresentable(isRecording: $isRecording, keyCode: $keyCode)
                .frame(width: 0, height: 0)
        )
    }

    private func keyName(for code: UInt16) -> String {
        let knownKeys: [UInt16: String] = [
            62: "Right Control", 59: "Left Control",
            58: "Left Option", 61: "Right Option",
            56: "Left Shift", 60: "Right Shift",
            55: "Left Command", 54: "Right Command",
            49: "Space", 36: "Return", 53: "Escape",
            48: "Tab",
        ]
        return knownKeys[code] ?? "Key \(code)"
    }
}

struct KeyRecorderRepresentable: NSViewRepresentable {
    @Binding var isRecording: Bool
    @Binding var keyCode: UInt16

    func makeNSView(context: Context) -> KeyRecorderNSView {
        let view = KeyRecorderNSView()
        view.onKeyRecorded = { code in
            keyCode = code
            isRecording = false
        }
        return view
    }

    func updateNSView(_ nsView: KeyRecorderNSView, context: Context) {
        nsView.isRecordingActive = isRecording
        if isRecording {
            nsView.window?.makeFirstResponder(nsView)
        }
    }
}

class KeyRecorderNSView: NSView {
    var onKeyRecorded: ((UInt16) -> Void)?
    var isRecordingActive = false

    override var acceptsFirstResponder: Bool { true }

    override func keyDown(with event: NSEvent) {
        if isRecordingActive {
            onKeyRecorded?(event.keyCode)
        }
    }

    override func flagsChanged(with event: NSEvent) {
        if isRecordingActive {
            onKeyRecorded?(event.keyCode)
        }
    }
}
```

- [ ] **Step 3: Create PreferencesView**

Create `Sources/LaserTool/UI/PreferencesView.swift`:

```swift
import SwiftUI

struct PreferencesView: View {
    @ObservedObject var prefs: PreferencesManager
    @State private var hotkeyCode: UInt16 = 62

    var body: some View {
        TabView {
            generalTab
                .tabItem { Label("General", systemImage: "gear") }
            styleTab
                .tabItem { Label("Styles", systemImage: "paintbrush") }
        }
        .frame(width: 450, height: 350)
        .onAppear {
            hotkeyCode = prefs.hotkeyKeyCode
        }
    }

    private var generalTab: some View {
        Form {
            Section("Hotkey") {
                HStack {
                    Text("Activation Key:")
                    Spacer()
                    HotkeyRecorderView(keyCode: $hotkeyCode)
                        .onChange(of: hotkeyCode) { _, newValue in
                            prefs.hotkeyKeyCode = newValue
                        }
                }
            }

            Section("Appearance") {
                HStack {
                    Text("Style:")
                    Spacer()
                    Picker("", selection: Binding(
                        get: { prefs.laserStyle },
                        set: { prefs.laserStyle = $0 }
                    )) {
                        ForEach(LaserStyle.allCases, id: \.self) { style in
                            Text(style.displayName).tag(style)
                        }
                    }
                    .frame(width: 160)
                }

                HStack {
                    Text("Color:")
                    Spacer()
                    Picker("", selection: Binding(
                        get: { prefs.laserColor },
                        set: { prefs.laserColor = $0 }
                    )) {
                        ForEach(LaserColor.allCases, id: \.self) { color in
                            Text(color.rawValue.capitalized).tag(color)
                        }
                    }
                    .frame(width: 160)
                }

                HStack {
                    Text("Size:")
                    Slider(value: Binding(
                        get: { prefs.laserSize },
                        set: { prefs.laserSize = $0 }
                    ), in: 10...60, step: 2)
                    Text("\(Int(prefs.laserSize))pt")
                        .frame(width: 40, alignment: .trailing)
                        .monospacedDigit()
                }
            }

            Section("General") {
                Toggle("Launch at Login", isOn: Binding(
                    get: { prefs.launchAtLogin },
                    set: { prefs.launchAtLogin = $0 }
                ))
            }
        }
        .padding()
    }

    private var styleTab: some View {
        Form {
            Section("Classic Dot — Trail") {
                Toggle("Enable Trail", isOn: Binding(
                    get: { prefs.trailEnabled },
                    set: { prefs.trailEnabled = $0 }
                ))
                HStack {
                    Text("Trail Length:")
                    Slider(value: Binding(
                        get: { Double(prefs.trailLength) },
                        set: { prefs.trailLength = Int($0) }
                    ), in: 10...50, step: 1)
                    Text("\(prefs.trailLength)")
                        .frame(width: 30, alignment: .trailing)
                        .monospacedDigit()
                }
            }

            Section("Spotlight") {
                HStack {
                    Text("Dim Opacity:")
                    Slider(value: Binding(
                        get: { prefs.spotlightDimOpacity },
                        set: { prefs.spotlightDimOpacity = $0 }
                    ), in: 0.4...0.8, step: 0.05)
                    Text("\(Int(prefs.spotlightDimOpacity * 100))%")
                        .frame(width: 40, alignment: .trailing)
                        .monospacedDigit()
                }
            }

            Section("Glowing Halo") {
                HStack {
                    Text("Pulse Speed:")
                    Slider(value: Binding(
                        get: { prefs.haloPulseSpeed },
                        set: { prefs.haloPulseSpeed = $0 }
                    ), in: 0.5...3.0, step: 0.1)
                    Text(String(format: "%.1fs", prefs.haloPulseSpeed))
                        .frame(width: 40, alignment: .trailing)
                        .monospacedDigit()
                }
            }

            Section("Crosshair") {
                HStack {
                    Text("Line Thickness:")
                    Slider(value: Binding(
                        get: { prefs.crosshairThickness },
                        set: { prefs.crosshairThickness = $0 }
                    ), in: 0.5...4.0, step: 0.5)
                    Text(String(format: "%.1fpt", prefs.crosshairThickness))
                        .frame(width: 50, alignment: .trailing)
                        .monospacedDigit()
                }
            }
        }
        .padding()
    }
}
```

- [ ] **Step 4: Build and verify**

Run: `swift build 2>&1`
Expected: `Build complete!`

- [ ] **Step 5: Commit**

```bash
git add Sources/LaserTool/UI/
git commit -m "feat: add SwiftUI preferences window with style picker and hotkey recorder"
```

---

### Task 10: Integration Wiring in AppDelegate

**Files:**
- Modify: `Sources/LaserTool/AppDelegate.swift`

- [ ] **Step 1: Wire all components together in AppDelegate**

Replace the contents of `Sources/LaserTool/AppDelegate.swift`:

```swift
import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private let prefs = PreferencesManager()
    private let overlayController = OverlayWindowController()
    private let hotkeyManager = HotkeyManager()
    private let mouseTracker = MouseTracker()
    private let gestureDetector: GestureDetector
    private let statusBar = StatusBarController()
    private let contextMenu = ContextMenuController()
    private var preferencesWindow: NSWindow?

    private var activeRenderer: LaserRenderer?
    private var isLaserActive = false

    override init() {
        // Create gesture detector with a temporary callback; we'll set the real one after super.init
        var onStateChangeHolder: ((Bool) -> Void)?
        gestureDetector = GestureDetector(doubleClickWindow: 0.3) { active in
            onStateChangeHolder?(active)
        }
        super.init()
        onStateChangeHolder = { [weak self] active in
            DispatchQueue.main.async {
                if active {
                    self?.activateLaser()
                } else {
                    self?.deactivateLaser()
                }
            }
        }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Check accessibility permission
        if !HotkeyManager.checkAccessibilityPermission() {
            NSLog("LaserTool: Accessibility permission required. Please grant it in System Settings > Privacy & Security > Accessibility.")
        }

        // Setup overlay windows
        overlayController.createOverlays()

        // Setup hotkey manager
        hotkeyManager.trackedKeyCode = prefs.hotkeyKeyCode
        hotkeyManager.onKeyDown = { [weak self] _ in
            self?.gestureDetector.keyDown()
        }
        hotkeyManager.onKeyUp = { [weak self] _ in
            self?.gestureDetector.keyUp()
        }
        hotkeyManager.onMouseMoved = { [weak self] point in
            self?.mouseTracker.handleMouseMoved(point)
        }
        hotkeyManager.onRightClick = { [weak self] point in
            guard let self = self, self.isLaserActive else { return }
            DispatchQueue.main.async {
                self.contextMenu.showMenu(at: NSPoint(x: point.x, y: point.y), on: self.overlayController)
            }
        }

        if !hotkeyManager.start() {
            NSLog("LaserTool: Failed to start hotkey manager.")
        }

        // Setup mouse tracker
        mouseTracker.onPositionChanged = { [weak self] point in
            guard let self = self, self.isLaserActive else { return }
            DispatchQueue.main.async {
                self.updateLaserPosition(point)
            }
        }

        // Setup status bar
        statusBar.setup()
        statusBar.onStyleChanged = { [weak self] style in
            self?.prefs.laserStyle = style
            if self?.isLaserActive == true {
                self?.switchRenderer()
            }
        }
        statusBar.onColorChanged = { [weak self] color in
            self?.prefs.laserColor = color
            self?.activeRenderer?.updateAppearance(
                color: color.nsColor,
                size: self?.prefs.laserSize ?? 24
            )
        }
        statusBar.onPreferencesRequested = { [weak self] in
            self?.showPreferences()
        }
        statusBar.onQuit = {
            NSApp.terminate(nil)
        }

        // Setup context menu
        contextMenu.onStyleChanged = { [weak self] style in
            self?.prefs.laserStyle = style
            self?.switchRenderer()
        }
        contextMenu.onColorChanged = { [weak self] color in
            self?.prefs.laserColor = color
            self?.activeRenderer?.updateAppearance(
                color: color.nsColor,
                size: self?.prefs.laserSize ?? 24
            )
        }
        contextMenu.onPreferencesRequested = { [weak self] in
            self?.showPreferences()
        }

        // Watch for screen changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screensChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )

        NSLog("LaserTool: Ready. Double-click and hold Right Control to activate.")
    }

    func applicationWillTerminate(_ notification: Notification) {
        hotkeyManager.stop()
        overlayController.tearDown()
    }

    // MARK: - Laser Activation

    private func activateLaser() {
        isLaserActive = true
        statusBar.updateIcon(active: true)

        let renderer = createRenderer(for: prefs.laserStyle)
        activeRenderer = renderer

        // Activate on all overlay views
        if let view = overlayController.overlayViews.first, let layer = view.layer {
            renderer.activate(on: layer)
        }

        // Set initial position to current mouse location
        let mouseLocation = NSEvent.mouseLocation
        updateLaserPosition(mouseLocation)
    }

    private func deactivateLaser() {
        isLaserActive = false
        statusBar.updateIcon(active: false)
        activeRenderer?.deactivate()
        activeRenderer = nil
    }

    private func switchRenderer() {
        guard isLaserActive else { return }
        let mousePos = NSEvent.mouseLocation
        activeRenderer?.deactivate()

        let renderer = createRenderer(for: prefs.laserStyle)
        activeRenderer = renderer

        if let view = overlayController.overlayViews.first, let layer = view.layer {
            renderer.activate(on: layer)
        }
        updateLaserPosition(mousePos)
    }

    private func updateLaserPosition(_ screenPoint: NSPoint) {
        guard let view = overlayController.overlayView(for: screenPoint) else { return }
        let localPoint = overlayController.convertToOverlay(screenPoint, in: view)
        activeRenderer?.updatePosition(localPoint)
    }

    private func createRenderer(for style: LaserStyle) -> LaserRenderer {
        switch style {
        case .classicDot:
            let r = ClassicDotRenderer()
            r.trailEnabled = prefs.trailEnabled
            r.trailLength = prefs.trailLength
            r.trailFadeSpeed = prefs.trailFadeSpeed
            r.updateAppearance(color: prefs.laserColor.nsColor, size: prefs.laserSize)
            return r
        case .spotlight:
            let r = SpotlightRenderer()
            r.dimOpacity = prefs.spotlightDimOpacity
            r.updateAppearance(color: prefs.laserColor.nsColor, size: prefs.laserSize)
            return r
        case .halo:
            let r = HaloRenderer()
            r.pulseSpeed = prefs.haloPulseSpeed
            r.updateAppearance(color: prefs.laserColor.nsColor, size: prefs.laserSize)
            return r
        case .crosshair:
            let r = CrosshairRenderer()
            r.lineThickness = prefs.crosshairThickness
            r.updateAppearance(color: prefs.laserColor.nsColor, size: prefs.laserSize)
            return r
        }
    }

    // MARK: - Preferences Window

    private func showPreferences() {
        if let window = preferencesWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let prefsView = PreferencesView(prefs: prefs)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 450, height: 350),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "LaserTool Preferences"
        window.contentView = NSHostingView(rootView: prefsView)
        window.center()
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        preferencesWindow = window
    }

    @objc private func screensChanged() {
        let wasActive = isLaserActive
        if wasActive { deactivateLaser() }
        overlayController.createOverlays()
        if wasActive { activateLaser() }
    }
}
```

- [ ] **Step 2: Build and verify**

Run: `swift build 2>&1`
Expected: `Build complete!`

- [ ] **Step 3: Run all tests**

Run: `swift test 2>&1`
Expected: All tests pass.

- [ ] **Step 4: Manual smoke test**

Run: `.build/debug/LaserTool`

Verify:
1. Menu bar icon appears (circle outline)
2. Double-click and hold Right Control → red laser dot appears following mouse
3. Release → laser disappears
4. Right-click while active → context menu with style/color options
5. Click menu bar icon → dropdown with styles, colors, preferences
6. Click Preferences → SwiftUI window opens with all settings

- [ ] **Step 5: Commit**

```bash
git add Sources/LaserTool/AppDelegate.swift
git commit -m "feat: wire all components together in AppDelegate — app is functional"
```

- [ ] **Step 6: Clean up placeholder test**

Delete `Tests/LaserToolTests/PlaceholderTest.swift`:

```bash
rm Tests/LaserToolTests/PlaceholderTest.swift
swift test 2>&1
git add -A Tests/
git commit -m "chore: remove placeholder test"
```
