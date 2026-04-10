import AppKit

class ContextMenuController {
    var onStyleChanged: ((LaserStyle) -> Void)?
    var onColorChanged: ((LaserColor) -> Void)?
    var onPreferencesRequested: (() -> Void)?

    func showMenu(at screenPoint: NSPoint, on overlayController: OverlayWindowController) {
        let menu = NSMenu()

        for style in LaserStyle.allCases {
            let item = NSMenuItem(title: style.displayName, action: #selector(styleSelected(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = style.rawValue
            menu.addItem(item)
        }

        menu.addItem(.separator())

        for color in LaserColor.allCases {
            let item = NSMenuItem(title: color.rawValue.capitalized, action: #selector(colorSelected(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = color.rawValue
            menu.addItem(item)
        }

        menu.addItem(.separator())

        let prefsItem = NSMenuItem(title: "Preferences...", action: #selector(openPreferences), keyEquivalent: "")
        prefsItem.target = self
        menu.addItem(prefsItem)

        overlayController.setIgnoresMouseEvents(false)

        if let view = overlayController.overlayView(for: screenPoint),
           let window = view.window {
            let windowPoint = window.convertPoint(fromScreen: screenPoint)
            menu.popUp(positioning: nil, at: windowPoint, in: view)
        }

        overlayController.setIgnoresMouseEvents(true)
    }

    @objc private func styleSelected(_ sender: NSMenuItem) {
        guard let rawValue = sender.representedObject as? String,
              let style = LaserStyle(rawValue: rawValue) else { return }
        onStyleChanged?(style)
    }

    @objc private func colorSelected(_ sender: NSMenuItem) {
        guard let rawValue = sender.representedObject as? String,
              let color = LaserColor(rawValue: rawValue) else { return }
        onColorChanged?(color)
    }

    @objc private func openPreferences() {
        onPreferencesRequested?()
    }
}
