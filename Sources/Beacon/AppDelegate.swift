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
    private var activeOverlayView: OverlayView?
    private var isLaserActive = false

    override init() {
        var onStateChangeHolder: ((Bool) -> Void)?
        gestureDetector = GestureDetector(doubleClickWindow: 0.3) { active in
            onStateChangeHolder?(active)
        }
        super.init()
        // CGEvent tap runs on the main run loop, so callbacks are already on the main thread
        onStateChangeHolder = { [weak self] active in
            if active {
                self?.activateLaser()
            } else {
                self?.deactivateLaser()
            }
        }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        let hasTrust = HotkeyManager.checkAccessibilityPermission()
        if !hasTrust {
            let alert = NSAlert()
            alert.messageText = "Accessibility Permission Required"
            alert.informativeText = "Beacon needs Accessibility access to detect hotkeys globally.\n\nGo to System Settings > Privacy & Security > Accessibility and enable Beacon, then relaunch the app."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Open System Settings")
            alert.addButton(withTitle: "Quit")
            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
            }
            NSApp.terminate(nil)
            return
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
        hotkeyManager.onRightClick = { [weak self] _ in
            guard let self = self, self.isLaserActive else { return }
            let screenPoint = NSEvent.mouseLocation
            self.contextMenu.showMenu(at: screenPoint, on: self.overlayController)
        }

        if !hotkeyManager.start() {
            let alert = NSAlert()
            alert.messageText = "Failed to Start Hotkey Monitor"
            alert.informativeText = "Beacon could not create the global event tap. Try:\n\n1. Toggle Accessibility permission off and on for Beacon\n2. Restart Beacon\n3. Restart your Mac if the issue persists"
            alert.alertStyle = .critical
            alert.addButton(withTitle: "Open System Settings")
            alert.addButton(withTitle: "Quit")
            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
            }
            NSApp.terminate(nil)
            return
        }

        mouseTracker.onPositionChanged = { [weak self] point in
            guard let self = self, self.isLaserActive else { return }
            self.updateLaserPosition(point)
        }

        // Propagate hotkey changes at runtime
        prefs.onHotkeyChanged = { [weak self] newKeyCode in
            self?.hotkeyManager.trackedKeyCode = newKeyCode
            self?.gestureDetector.reset()
        }

        // Size changes — lightweight, just update appearance on existing renderer
        prefs.onAppearanceChanged = { [weak self] in
            guard let self = self, self.isLaserActive else { return }
            self.activeRenderer?.updateAppearance(
                color: self.prefs.laserColor.nsColor,
                size: self.prefs.laserSize
            )
        }

        // Style-specific settings (trail length, dim opacity, etc.) — need renderer rebuild
        prefs.onRendererSettingsChanged = { [weak self] in
            guard let self = self, self.isLaserActive else { return }
            self.switchRenderer()
        }

        statusBar.setup(style: prefs.laserStyle, color: prefs.laserColor)
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
            self?.statusBar.updateStyle(style)
            self?.switchRenderer()
        }
        contextMenu.onColorChanged = { [weak self] color in
            self?.prefs.laserColor = color
            self?.statusBar.updateColor(color)
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

        NSLog("Beacon: Ready. Double-click and hold activation key to activate.")
    }

    func applicationWillTerminate(_ notification: Notification) {
        hotkeyManager.stop()
        overlayController.tearDown()
    }

    // MARK: - Laser Activation

    private func activateLaser() {
        isLaserActive = true
        statusBar.updateIcon(active: true)

        let mouseLocation = NSEvent.mouseLocation
        let renderer = createRenderer(for: prefs.laserStyle)
        activeRenderer = renderer

        if let view = overlayController.overlayView(for: mouseLocation), let layer = view.layer {
            renderer.activate(on: layer)
            activeOverlayView = view
        }

        updateLaserPosition(mouseLocation)
    }

    private func deactivateLaser() {
        isLaserActive = false
        statusBar.updateIcon(active: false)
        activeRenderer?.deactivate()
        activeRenderer = nil
        activeOverlayView = nil
    }

    private func switchRenderer() {
        guard isLaserActive else { return }
        let mousePos = NSEvent.mouseLocation
        activeRenderer?.deactivate()

        let renderer = createRenderer(for: prefs.laserStyle)
        activeRenderer = renderer

        if let view = overlayController.overlayView(for: mousePos), let layer = view.layer {
            renderer.activate(on: layer)
            activeOverlayView = view
        }
        updateLaserPosition(mousePos)
    }

    private func updateLaserPosition(_ screenPoint: NSPoint) {
        guard let renderer = activeRenderer else { return }

        // Check if mouse moved to a different screen
        if let newView = overlayController.overlayView(for: screenPoint),
           newView !== activeOverlayView,
           let newLayer = newView.layer {
            renderer.deactivate()
            renderer.activate(on: newLayer)
            activeOverlayView = newView
        }

        guard let view = activeOverlayView else { return }
        let localPoint = overlayController.convertToOverlay(screenPoint, in: view)
        renderer.updatePosition(localPoint)
    }

    private func createRenderer(for style: LaserStyle) -> LaserRenderer {
        switch style {
        case .classicDot:
            let r = ClassicDotRenderer()
            r.trailEnabled = prefs.trailEnabled
            r.trailLength = prefs.trailLength
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
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 380),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Beacon Preferences"
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
