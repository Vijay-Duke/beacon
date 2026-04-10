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

    func overlayView(for point: NSPoint) -> OverlayView? {
        for (i, window) in windows.enumerated() {
            if NSPointInRect(point, window.frame) {
                return overlayViews[i]
            }
        }
        return overlayViews.first
    }

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
