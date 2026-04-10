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
        let neededCount = max(0, points.count - 1)

        while trailLayers.count < neededCount {
            let tl = CAShapeLayer()
            hostLayer.insertSublayer(tl, below: dotLayer)
            trailLayers.append(tl)
        }
        while trailLayers.count > neededCount {
            trailLayers.removeLast().removeFromSuperlayer()
        }

        for i in 0..<neededCount {
            let tl = trailLayers[i]
            let progress = CGFloat(i + 1) / CGFloat(points.count)
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
