import XCTest
@testable import TuckBarCore

@MainActor
final class IconRegistryStoreTests: XCTestCase {
    func testMergePreservesPlacementAndMarksMissingUnavailable() throws {
        let store = IconRegistryStore(configURL: temporaryConfigURL())
        let original = makeRecord(id: "one", displayName: "Original")
        store.merge(scannedRecords: [original])
        store.setPlacementMode(.virtualMenu, for: "one")

        let renamed = makeRecord(id: "one", displayName: "Renamed")
        let second = makeRecord(id: "two", displayName: "Second")
        store.merge(scannedRecords: [renamed, second])

        XCTAssertEqual(store.records.map(\.id), ["one", "two"])
        XCTAssertEqual(store.records[0].displayName, "Renamed")
        XCTAssertEqual(store.records[0].placementMode, .virtualMenu)
        XCTAssertTrue(store.records[0].isAvailable)

        store.merge(scannedRecords: [second])

        let first = try XCTUnwrap(store.records.first(where: { $0.id == "one" }))
        XCTAssertFalse(first.isAvailable)
    }

    func testPersistenceRoundTrip() throws {
        let url = temporaryConfigURL()
        let firstStore = IconRegistryStore(configURL: url)
        firstStore.merge(scannedRecords: [
            makeRecord(id: "one", displayName: "One"),
            makeRecord(id: "two", displayName: "Two")
        ])
        firstStore.setPlacementMode(.realMenuBar, for: "two")

        let secondStore = IconRegistryStore(configURL: url)
        secondStore.load()

        XCTAssertEqual(secondStore.records.count, 2)
        XCTAssertEqual(secondStore.records.first(where: { $0.id == "two" })?.placementMode, .realMenuBar)
    }

    private func makeRecord(id: String, displayName: String) -> MenuBarItemRecord {
        MenuBarItemRecord(
            id: id,
            bundleIdentifier: "com.example.\(id)",
            processName: "Example",
            displayName: displayName,
            title: displayName,
            help: nil,
            lastKnownFrame: nil
        )
    }

    private func temporaryConfigURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
            .appendingPathComponent("config.json")
    }
}
