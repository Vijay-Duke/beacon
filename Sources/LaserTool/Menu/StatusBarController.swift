import AppKit
import SwiftUI

class StatusBarController {
    private var statusItem: NSStatusItem?
    var onStyleChanged: ((LaserStyle) -> Void)?
    var onColorChanged: ((LaserColor) -> Void)?
    var onPreferencesRequested: (() -> Void)?
    var onQuit: (() -> Void)?
    private var currentStyle: LaserStyle = .classicDot

    func setup() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        updateIcon(active: false)
        buildMenu()
    }

    func updateIcon(active: Bool) {
        guard let button = statusItem?.button else { return }
        if let image = NSImage(systemSymbolName: active ? "circle.fill" : "circle",
                               accessibilityDescription: "LaserTool") {
            image.isTemplate = true
            button.image = image
        }
    }

    private func buildMenu() {
        let menu = NSMenu()

        let styleItem = NSMenuItem(title: "Style", action: nil, keyEquivalent: "")
        let styleMenu = NSMenu()
        for style in LaserStyle.allCases {
            let item = NSMenuItem(title: style.displayName, action: #selector(styleSelected(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = style.rawValue
            if style == currentStyle { item.state = .on }
            styleMenu.addItem(item)
        }
        styleItem.submenu = styleMenu
        menu.addItem(styleItem)

        let colorItem = NSMenuItem(title: "Color", action: nil, keyEquivalent: "")
        let colorMenu = NSMenu()
        for color in LaserColor.allCases {
            let item = NSMenuItem(title: color.rawValue.capitalized, action: #selector(colorSelected(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = color.rawValue
            colorMenu.addItem(item)
        }
        colorItem.submenu = colorMenu
        menu.addItem(colorItem)

        menu.addItem(.separator())

        let prefsItem = NSMenuItem(title: "Preferences...", action: #selector(openPreferences), keyEquivalent: ",")
        prefsItem.target = self
        menu.addItem(prefsItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Quit LaserTool", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem?.menu = menu
    }

    @objc private func styleSelected(_ sender: NSMenuItem) {
        guard let rawValue = sender.representedObject as? String,
              let style = LaserStyle(rawValue: rawValue) else { return }
        currentStyle = style
        onStyleChanged?(style)
        buildMenu()
    }

    @objc private func colorSelected(_ sender: NSMenuItem) {
        guard let rawValue = sender.representedObject as? String,
              let color = LaserColor(rawValue: rawValue) else { return }
        onColorChanged?(color)
    }

    @objc private func openPreferences() {
        onPreferencesRequested?()
    }

    @objc private func quit() {
        onQuit?()
    }
}

extension LaserStyle {
    var displayName: String {
        switch self {
        case .classicDot: return "Classic Dot"
        case .spotlight: return "Spotlight"
        case .halo: return "Glowing Halo"
        case .crosshair: return "Crosshair"
        }
    }
}
