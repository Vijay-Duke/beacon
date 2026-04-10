import AppKit

enum LaserStyle: String, CaseIterable {
    case classicDot = "classicDot"
    case spotlight = "spotlight"
    case halo = "halo"
    case crosshair = "crosshair"
}

enum LaserColor: String, CaseIterable {
    case red, green, blue, amber, white

    var nsColor: NSColor {
        switch self {
        case .red: return NSColor(red: 1.0, green: 0.2, blue: 0.2, alpha: 1.0)
        case .green: return NSColor(red: 0.0, green: 1.0, blue: 0.53, alpha: 1.0)
        case .blue: return NSColor(red: 0.2, green: 0.6, blue: 1.0, alpha: 1.0)
        case .amber: return NSColor(red: 1.0, green: 0.66, blue: 0.0, alpha: 1.0)
        case .white: return NSColor.white
        }
    }
}

class PreferencesManager: ObservableObject {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var laserStyle: LaserStyle {
        get { LaserStyle(rawValue: defaults.string(forKey: "laserStyle") ?? "") ?? .classicDot }
        set { defaults.set(newValue.rawValue, forKey: "laserStyle"); objectWillChange.send() }
    }

    var laserColor: LaserColor {
        get { LaserColor(rawValue: defaults.string(forKey: "laserColor") ?? "") ?? .red }
        set { defaults.set(newValue.rawValue, forKey: "laserColor") }
    }

    var laserSize: CGFloat {
        get {
            let val = defaults.double(forKey: "laserSize")
            return val > 0 ? val : 24.0
        }
        set { defaults.set(newValue, forKey: "laserSize") }
    }

    var trailEnabled: Bool {
        get {
            if defaults.object(forKey: "trailEnabled") == nil { return true }
            return defaults.bool(forKey: "trailEnabled")
        }
        set { defaults.set(newValue, forKey: "trailEnabled") }
    }

    var trailLength: Int {
        get {
            let val = defaults.integer(forKey: "trailLength")
            return val > 0 ? val : 30
        }
        set { defaults.set(newValue, forKey: "trailLength") }
    }

    var trailFadeSpeed: Double {
        get {
            let val = defaults.double(forKey: "trailFadeSpeed")
            return val > 0 ? val : 0.3
        }
        set { defaults.set(newValue, forKey: "trailFadeSpeed") }
    }

    var spotlightDimOpacity: Double {
        get {
            let val = defaults.double(forKey: "spotlightDimOpacity")
            return val > 0 ? val : 0.6
        }
        set { defaults.set(newValue, forKey: "spotlightDimOpacity") }
    }

    var haloPulseSpeed: Double {
        get {
            let val = defaults.double(forKey: "haloPulseSpeed")
            return val > 0 ? val : 1.2
        }
        set { defaults.set(newValue, forKey: "haloPulseSpeed") }
    }

    var crosshairThickness: CGFloat {
        get {
            let val = defaults.double(forKey: "crosshairThickness")
            return val > 0 ? val : 1.5
        }
        set { defaults.set(newValue, forKey: "crosshairThickness") }
    }

    var hotkeyKeyCode: UInt16 {
        get {
            if defaults.object(forKey: "hotkeyKeyCode") == nil { return 62 }
            return UInt16(defaults.integer(forKey: "hotkeyKeyCode"))
        }
        set { defaults.set(Int(newValue), forKey: "hotkeyKeyCode") }
    }

    var launchAtLogin: Bool {
        get { defaults.bool(forKey: "launchAtLogin") }
        set { defaults.set(newValue, forKey: "launchAtLogin") }
    }
}
