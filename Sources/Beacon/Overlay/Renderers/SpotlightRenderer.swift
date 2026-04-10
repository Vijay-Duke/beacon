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

        let fullPath = CGMutablePath()
        fullPath.addRect(hostLayer.bounds)
        let spotlightRadius = size * 3
        let spotlightRect = CGRect(
            x: point.x - spotlightRadius,
            y: point.y - spotlightRadius,
            width: spotlightRadius * 2,
            height: spotlightRadius * 2
        )
        fullPath.addEllipse(in: spotlightRect)
        maskLayer.path = fullPath

        CATransaction.commit()
    }

    func updateAppearance(color: NSColor, size: CGFloat) {
        self.size = size
        dimLayer?.backgroundColor = NSColor.black.withAlphaComponent(dimOpacity).cgColor
    }
}
