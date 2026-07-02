import XCTest
@testable import TuckBarCore

final class MenuBarItemIdentityTests: XCTestCase {
    func testStableIdentityPrefersBundleProcessAndTitle() {
        let id = MenuBarItemIdentity.makeID(
            bundleIdentifier: "com.example.Calendar",
            processName: "Calendar Helper",
            title: "Next Meeting",
            help: "Ignored",
            fallbackIndex: 2
        )

        XCTAssertEqual(id, "com.example.calendar::calendar-helper::next-meeting")
    }

    func testIdentityFallsBackToHelpThenIndex() {
        let helpID = MenuBarItemIdentity.makeID(
            bundleIdentifier: nil,
            processName: "Wi Fi",
            title: "",
            help: "Network Status",
            fallbackIndex: 4
        )
        let indexedID = MenuBarItemIdentity.makeID(
            bundleIdentifier: nil,
            processName: "Wi Fi",
            title: nil,
            help: nil,
            fallbackIndex: 4
        )

        XCTAssertEqual(helpID, "unknown-bundle::wi-fi::network-status")
        XCTAssertEqual(indexedID, "unknown-bundle::wi-fi::item-4")
    }
}
