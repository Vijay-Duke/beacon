import Foundation

class GestureDetector {
    enum State {
        case idle
        case waitingForSecondPress
        case active
    }

    private(set) var state: State = .idle
    private let doubleClickWindow: TimeInterval
    private let onStateChange: (Bool) -> Void
    private var firstPressTime: Date?
    private var windowTimer: Timer?

    init(doubleClickWindow: TimeInterval = 0.3, onStateChange: @escaping (Bool) -> Void) {
        self.doubleClickWindow = doubleClickWindow
        self.onStateChange = onStateChange
    }

    func keyDown() {
        switch state {
        case .idle:
            firstPressTime = Date()
            state = .waitingForSecondPress

        case .waitingForSecondPress:
            windowTimer?.invalidate()
            windowTimer = nil
            state = .active
            onStateChange(true)

        case .active:
            break
        }
    }

    func keyUp() {
        switch state {
        case .idle:
            break

        case .waitingForSecondPress:
            windowTimer?.invalidate()
            let timer = Timer(timeInterval: doubleClickWindow, repeats: false) { [weak self] _ in
                self?.state = .idle
                self?.firstPressTime = nil
                self?.windowTimer = nil
            }
            // Use .common mode so the timer fires during menu tracking and other modal events
            RunLoop.current.add(timer, forMode: .common)
            windowTimer = timer

        case .active:
            state = .idle
            firstPressTime = nil
            onStateChange(false)
        }
    }

    func reset() {
        windowTimer?.invalidate()
        windowTimer = nil
        if state == .active {
            onStateChange(false)
        }
        state = .idle
        firstPressTime = nil
    }
}
