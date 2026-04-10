import AppKit

class MouseTracker {
    var onPositionChanged: ((NSPoint) -> Void)?

    func handleMouseMoved(_ cgPoint: CGPoint) {
        // Use NSEvent.mouseLocation which is already in Cocoa screen coordinates
        // (bottom-left origin, y-up). This works correctly on all monitors.
        let nsPoint = NSEvent.mouseLocation
        onPositionChanged?(nsPoint)
    }
}
