import XCTest
@testable import Beacon

final class RingBufferTests: XCTestCase {
    func testEmptyBuffer() {
        let buffer = RingBuffer<NSPoint>(capacity: 5)
        XCTAssertEqual(buffer.count, 0)
        XCTAssertTrue(buffer.allElements.isEmpty)
    }

    func testAppendWithinCapacity() {
        var buffer = RingBuffer<Int>(capacity: 3)
        buffer.append(1)
        buffer.append(2)
        XCTAssertEqual(buffer.count, 2)
        XCTAssertEqual(buffer.allElements, [1, 2])
    }

    func testAppendOverCapacity() {
        var buffer = RingBuffer<Int>(capacity: 3)
        buffer.append(1)
        buffer.append(2)
        buffer.append(3)
        buffer.append(4)
        XCTAssertEqual(buffer.count, 3)
        XCTAssertEqual(buffer.allElements, [2, 3, 4])
    }

    func testClear() {
        var buffer = RingBuffer<Int>(capacity: 3)
        buffer.append(1)
        buffer.append(2)
        buffer.clear()
        XCTAssertEqual(buffer.count, 0)
        XCTAssertTrue(buffer.allElements.isEmpty)
    }

    func testCapacityChange() {
        var buffer = RingBuffer<Int>(capacity: 5)
        buffer.append(1)
        buffer.append(2)
        buffer.append(3)
        buffer.capacity = 2
        XCTAssertEqual(buffer.count, 2)
        XCTAssertEqual(buffer.allElements, [2, 3])
    }
}
