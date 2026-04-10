import AppKit

let app = NSApplication.shared
// Must retain delegate — NSApplication.delegate is weak
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)

// Hold strong reference so ARC doesn't deallocate the delegate
withExtendedLifetime(delegate) {
    app.run()
}
