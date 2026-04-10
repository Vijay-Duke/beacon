import AppKit
import CoreGraphics

class HotkeyManager {
    fileprivate var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    var onKeyDown: ((UInt16) -> Void)?
    var onKeyUp: ((UInt16) -> Void)?
    var onRightClick: ((CGPoint) -> Void)?
    var onMouseMoved: ((CGPoint) -> Void)?
    var trackedKeyCode: UInt16 = 62

    func start() -> Bool {
        let eventMask: CGEventMask = (
            (1 << CGEventType.keyDown.rawValue) |
            (1 << CGEventType.keyUp.rawValue) |
            (1 << CGEventType.flagsChanged.rawValue) |
            (1 << CGEventType.mouseMoved.rawValue) |
            (1 << CGEventType.leftMouseDragged.rawValue) |
            (1 << CGEventType.rightMouseDown.rawValue)
        )

        guard let tap = CGEvent.tapCreate(
            tap: .cgAnnotatedSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: eventMask,
            callback: hotkeyCallback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            NSLog("LaserTool: Failed to create event tap. Check Accessibility permissions.")
            return false
        }

        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        return true
    }

    func stop() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
        }
        eventTap = nil
        runLoopSource = nil
    }

    fileprivate func handleEvent(_ type: CGEventType, event: CGEvent) {
        switch type {
        case .keyDown:
            let keyCode = UInt16(event.getIntegerValueField(.keyboardEventKeycode))
            if keyCode == trackedKeyCode {
                if event.getIntegerValueField(.keyboardEventAutorepeat) == 0 {
                    onKeyDown?(keyCode)
                }
            }

        case .keyUp:
            let keyCode = UInt16(event.getIntegerValueField(.keyboardEventKeycode))
            if keyCode == trackedKeyCode {
                onKeyUp?(keyCode)
            }

        case .flagsChanged:
            let keyCode = UInt16(event.getIntegerValueField(.keyboardEventKeycode))
            if keyCode == trackedKeyCode {
                let flags = event.flags
                let isPressed = isModifierPressed(keyCode: keyCode, flags: flags)
                if isPressed {
                    onKeyDown?(keyCode)
                } else {
                    onKeyUp?(keyCode)
                }
            }

        case .mouseMoved, .leftMouseDragged:
            let location = event.location
            onMouseMoved?(location)

        case .rightMouseDown:
            let location = event.location
            onRightClick?(location)

        default:
            break
        }
    }

    private func isModifierPressed(keyCode: UInt16, flags: CGEventFlags) -> Bool {
        switch keyCode {
        case 62, 59: return flags.contains(.maskControl)
        case 58, 61: return flags.contains(.maskAlternate)
        case 56, 60: return flags.contains(.maskShift)
        case 55, 54: return flags.contains(.maskCommand)
        default: return false
        }
    }

    static func checkAccessibilityPermission() -> Bool {
        let trusted = AXIsProcessTrustedWithOptions(
            [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
        )
        return trusted
    }
}

private func hotkeyCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    userInfo: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    guard let userInfo = userInfo else { return Unmanaged.passRetained(event) }
    let manager = Unmanaged<HotkeyManager>.fromOpaque(userInfo).takeUnretainedValue()

    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
        if let tap = manager.eventTap {
            CGEvent.tapEnable(tap: tap, enable: true)
        }
        return Unmanaged.passRetained(event)
    }

    manager.handleEvent(type, event: event)
    return Unmanaged.passRetained(event)
}
