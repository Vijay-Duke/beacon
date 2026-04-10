import XCTest
@testable import LaserTool

final class GestureDetectorTests: XCTestCase {
    var detector: GestureDetector!
    var activations: [Bool]!

    override func setUp() {
        super.setUp()
        activations = []
        detector = GestureDetector(doubleClickWindow: 0.3) { [unowned self] active in
            self.activations.append(active)
        }
    }

    func testSinglePressDoesNotActivate() {
        detector.keyDown()
        detector.keyUp()
        RunLoop.current.run(until: Date().addingTimeInterval(0.4))
        XCTAssertTrue(activations.isEmpty)
    }

    func testDoubleClickAndHoldActivates() {
        detector.keyDown()
        detector.keyUp()
        detector.keyDown()
        XCTAssertEqual(activations, [true])
    }

    func testReleaseAfterActivationDeactivates() {
        detector.keyDown()
        detector.keyUp()
        detector.keyDown()
        XCTAssertEqual(activations, [true])
        detector.keyUp()
        XCTAssertEqual(activations, [true, false])
    }

    func testDoubleClickTooSlowDoesNotActivate() {
        detector.keyDown()
        detector.keyUp()
        RunLoop.current.run(until: Date().addingTimeInterval(0.4))
        detector.keyDown()
        detector.keyUp()
        XCTAssertTrue(activations.isEmpty)
    }

    func testRepeatedActivationCycles() {
        detector.keyDown()
        detector.keyUp()
        detector.keyDown()
        XCTAssertEqual(activations, [true])
        detector.keyUp()
        XCTAssertEqual(activations, [true, false])

        RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        detector.keyDown()
        detector.keyUp()
        detector.keyDown()
        XCTAssertEqual(activations, [true, false, true])
        detector.keyUp()
        XCTAssertEqual(activations, [true, false, true, false])
    }
}
