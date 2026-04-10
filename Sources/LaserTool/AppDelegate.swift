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
        if !HotkeyManager.checkAccessibilityPermission() {
            NSLog("LaserTool: Accessibility permission required. Please grant it in System Settings > Privacy & Security > Accessibility.")
        }

        overlayController.createOverlays()

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

        mouseTracker.onPositionChanged = { [weak self] point in
            guard let self = self, self.isLaserActive else { return }
            DispatchQueue.main.async {
                self.updateLaserPosition(point)
            }
        }

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

        if let view = overlayController.overlayViews.first, let layer = view.layer {
            renderer.activate(on: layer)
        }

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
