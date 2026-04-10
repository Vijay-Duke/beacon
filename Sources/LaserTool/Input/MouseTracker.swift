import AppKit

class MouseTracker {
    var onPositionChanged: ((NSPoint) -> Void)?

    func handleMouseMoved(_ cgPoint: CGPoint) {
        let nsPoint = NSPoint(x: cgPoint.x, y: cgPoint.y)
        onPositionChanged?(nsPoint)
    }
}
