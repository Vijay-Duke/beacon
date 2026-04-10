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
        if let host = hostLayer {
            let savedPosition = containerLayer?.position ?? .zero
            deactivate()
            activate(on: host)
            updatePosition(savedPosition)
        }
    }
}
