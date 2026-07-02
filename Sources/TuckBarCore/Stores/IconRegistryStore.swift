import Foundation
import SwiftUI

@MainActor
final class IconRegistryStore: ObservableObject {
    @Published private(set) var records: [MenuBarItemRecord] = []
    @Published var lastScanError: String?

    private let configURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(configURL: URL = IconRegistryStore.defaultConfigURL()) {
        self.configURL = configURL
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    nonisolated static func defaultConfigURL() -> URL {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        return support.appendingPathComponent("TuckBar", isDirectory: true).appendingPathComponent("config.json")
    }

    func load() {
        guard FileManager.default.fileExists(atPath: configURL.path) else { return }
        do {
            let data = try Data(contentsOf: configURL)
            records = try decoder.decode([MenuBarItemRecord].self, from: data).sortedForDisplay()
        } catch {
            lastScanError = "Could not load config: \(error.localizedDescription)"
        }
    }

    func save() {
        do {
            try FileManager.default.createDirectory(at: configURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            let data = try encoder.encode(records)
            try data.write(to: configURL, options: .atomic)
        } catch {
            lastScanError = "Could not save config: \(error.localizedDescription)"
        }
    }

    func merge(scannedRecords: [MenuBarItemRecord]) {
        var existing = Dictionary(uniqueKeysWithValues: records.map { ($0.id, $0) })
        let scannedIDs = Set(scannedRecords.map(\.id))
        let nextSortIndex = (records.map(\.sortIndex).max() ?? -1) + 1
        var appendedCount = 0

        for scanned in scannedRecords {
            if var record = existing[scanned.id] {
                record.bundleIdentifier = scanned.bundleIdentifier
                record.processName = scanned.processName
                record.displayName = scanned.displayName
                record.title = scanned.title
                record.help = scanned.help
                record.lastKnownFrame = scanned.lastKnownFrame
                record.lastSeenAt = scanned.lastSeenAt
                record.isAvailable = true
                existing[scanned.id] = record
            } else {
                var newRecord = scanned
                newRecord.sortIndex = nextSortIndex + appendedCount
                newRecord.placementMode = .both
                newRecord.hideSupportStatus = .unknown
                existing[scanned.id] = newRecord
                appendedCount += 1
            }
        }

        for id in existing.keys where !scannedIDs.contains(id) {
            existing[id]?.isAvailable = false
        }

        records = Array(existing.values).sortedForDisplay().renumbered()
        save()
    }

    func markAllUnavailable() {
        records = records.map {
            var copy = $0
            copy.isAvailable = false
            return copy
        }
    }

    func move(from source: IndexSet, to destination: Int) {
        records.move(fromOffsets: source, toOffset: destination)
        records = records.renumbered()
        save()
    }

    func setPlacementMode(_ mode: PlacementMode, for id: String) {
        guard let index = records.firstIndex(where: { $0.id == id }) else { return }
        records[index].placementMode = mode
        save()
    }

    func updateHideSupportStatus(_ status: HideSupportStatus, for id: String) {
        guard let index = records.firstIndex(where: { $0.id == id }) else { return }
        records[index].hideSupportStatus = status
        save()
    }

    func visibleShelfRecords() -> [MenuBarItemRecord] {
        records.filter { $0.placementMode == .virtualMenu || $0.placementMode == .both }
    }
}

private extension Array where Element == MenuBarItemRecord {
    func sortedForDisplay() -> [MenuBarItemRecord] {
        sorted {
            if $0.sortIndex != $1.sortIndex { return $0.sortIndex < $1.sortIndex }
            return $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending
        }
    }

    func renumbered() -> [MenuBarItemRecord] {
        enumerated().map { index, record in
            var copy = record
            copy.sortIndex = index
            return copy
        }
    }
}
