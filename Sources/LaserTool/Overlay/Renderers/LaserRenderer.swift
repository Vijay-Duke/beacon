import AppKit
import QuartzCore

struct RingBuffer<T> {
    private var buffer: [T] = []
    private var head: Int = 0
    private(set) var count: Int = 0
    var capacity: Int {
        didSet {
            if capacity < count {
                let elements = allElements
                buffer = Array(elements.suffix(capacity))
                head = 0
                count = buffer.count
            }
        }
    }

    init(capacity: Int) {
        self.capacity = capacity
        self.buffer = []
        self.buffer.reserveCapacity(capacity)
    }

    mutating func append(_ element: T) {
        if buffer.count < capacity {
            buffer.append(element)
            count = buffer.count
        } else {
            buffer[head] = element
            head = (head + 1) % capacity
            count = capacity
        }
    }

    var allElements: [T] {
        guard count > 0 else { return [] }
        if buffer.count < capacity {
            return buffer
        }
        return Array(buffer[head...]) + Array(buffer[..<head])
    }

    mutating func clear() {
        buffer.removeAll()
        head = 0
        count = 0
    }
}

protocol LaserRenderer: AnyObject {
    func activate(on layer: CALayer)
    func deactivate()
    func updatePosition(_ point: CGPoint)
    func updateAppearance(color: NSColor, size: CGFloat)
}
