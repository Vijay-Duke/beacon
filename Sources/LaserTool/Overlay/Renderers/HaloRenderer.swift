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
