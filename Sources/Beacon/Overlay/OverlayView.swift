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
