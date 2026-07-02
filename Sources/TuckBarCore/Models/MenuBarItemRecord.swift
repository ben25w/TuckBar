import CoreGraphics
import Foundation

public enum PlacementMode: String, Codable, CaseIterable, Identifiable {
    case realMenuBar
    case virtualMenu
    case both

    public var id: String { rawValue }

    var label: String {
        switch self {
        case .realMenuBar: "Real"
        case .virtualMenu: "Shelf"
        case .both: "Both"
        }
    }
}

public enum HideSupportStatus: String, Codable, Equatable {
    case unknown
    case hiddenSupported
    case virtualOnlyUnsupported
}

public struct CodableRect: Codable, Equatable {
    public var x: Double
    public var y: Double
    public var width: Double
    public var height: Double

    public init(_ rect: CGRect) {
        self.x = rect.origin.x
        self.y = rect.origin.y
        self.width = rect.size.width
        self.height = rect.size.height
    }

    public var cgRect: CGRect {
        CGRect(x: x, y: y, width: width, height: height)
    }
}

public struct MenuBarItemRecord: Codable, Identifiable, Equatable {
    public var id: String
    public var bundleIdentifier: String?
    public var processName: String
    public var displayName: String
    public var title: String?
    public var help: String?
    public var placementMode: PlacementMode
    public var sortIndex: Int
    public var lastKnownFrame: CodableRect?
    public var lastSeenAt: Date
    public var hideSupportStatus: HideSupportStatus
    public var isAvailable: Bool

    public init(
        id: String,
        bundleIdentifier: String?,
        processName: String,
        displayName: String,
        title: String?,
        help: String?,
        placementMode: PlacementMode = .both,
        sortIndex: Int = 0,
        lastKnownFrame: CodableRect?,
        lastSeenAt: Date = Date(),
        hideSupportStatus: HideSupportStatus = .unknown,
        isAvailable: Bool = true
    ) {
        self.id = id
        self.bundleIdentifier = bundleIdentifier
        self.processName = processName
        self.displayName = displayName
        self.title = title
        self.help = help
        self.placementMode = placementMode
        self.sortIndex = sortIndex
        self.lastKnownFrame = lastKnownFrame
        self.lastSeenAt = lastSeenAt
        self.hideSupportStatus = hideSupportStatus
        self.isAvailable = isAvailable
    }
}

public enum MenuBarItemIdentity {
    public static func makeID(bundleIdentifier: String?, processName: String, title: String?, help: String?, fallbackIndex: Int) -> String {
        let bundle = normalized(bundleIdentifier) ?? "unknown-bundle"
        let process = normalized(processName) ?? "unknown-process"
        let itemName = normalized(title) ?? normalized(help) ?? "item-\(fallbackIndex)"
        return [bundle, process, itemName].joined(separator: "::")
    }

    private static func normalized(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return trimmed
            .lowercased()
            .replacingOccurrences(of: "\\s+", with: "-", options: .regularExpression)
            .replacingOccurrences(of: "[^a-z0-9._:-]", with: "", options: .regularExpression)
    }
}
