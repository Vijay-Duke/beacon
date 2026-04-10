import XCTest
@testable import LaserTool

final class PreferencesManagerTests: XCTestCase {
    var prefs: PreferencesManager!

    override func setUp() {
        super.setUp()
        prefs = PreferencesManager(defaults: UserDefaults(suiteName: "test-\(UUID().uuidString)")!)
    }

    func testDefaultStyle() {
        XCTAssertEqual(prefs.laserStyle, .classicDot)
    }

    func testDefaultColor() {
        XCTAssertEqual(prefs.laserColor, .red)
    }

    func testDefaultSize() {
        XCTAssertEqual(prefs.laserSize, 24.0, accuracy: 0.01)
    }

    func testDefaultTrailEnabled() {
        XCTAssertTrue(prefs.trailEnabled)
    }

    func testDefaultTrailLength() {
        XCTAssertEqual(prefs.trailLength, 30)
    }

    func testDefaultSpotlightOpacity() {
        XCTAssertEqual(prefs.spotlightDimOpacity, 0.6, accuracy: 0.01)
    }

    func testDefaultHaloPulseSpeed() {
        XCTAssertEqual(prefs.haloPulseSpeed, 1.2, accuracy: 0.01)
    }

    func testDefaultCrosshairThickness() {
        XCTAssertEqual(prefs.crosshairThickness, 1.5, accuracy: 0.01)
    }

    func testDefaultHotkeyCode() {
        XCTAssertEqual(prefs.hotkeyKeyCode, 62)
    }

    func testSetAndGetStyle() {
        prefs.laserStyle = .spotlight
        XCTAssertEqual(prefs.laserStyle, .spotlight)
    }

    func testSetAndGetSize() {
        prefs.laserSize = 40.0
        XCTAssertEqual(prefs.laserSize, 40.0, accuracy: 0.01)
    }

    func testSetAndGetColor() {
        prefs.laserColor = .green
        XCTAssertEqual(prefs.laserColor, .green)
    }
}
