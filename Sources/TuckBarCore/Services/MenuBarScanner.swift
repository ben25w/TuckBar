import AppKit
import ApplicationServices

protocol MenuBarScanning {
    func scan() throws -> [MenuBarItemProxy]
}

final class MenuBarScanner: MenuBarScanning {
    private let accessibilityClient: AccessibilityClient

    init(accessibilityClient: AccessibilityClient) {
        self.accessibilityClient = accessibilityClient
    }

    func scan() throws -> [MenuBarItemProxy] {
        var proxies: [MenuBarItemProxy] = []

        for application in accessibilityClient.runningApplications() {
            let appElement = accessibilityClient.applicationElement(for: application.processIdentifier)
            guard let extrasMenuBar: AXUIElement = try accessibilityClient.copyAttribute("AXExtrasMenuBar", from: appElement),
                  let children: [AXUIElement] = try accessibilityClient.copyAttribute(kAXChildrenAttribute, from: extrasMenuBar),
                  !children.isEmpty else {
                continue
            }

            for (index, child) in children.enumerated() {
                let title: String? = try accessibilityClient.copyAttribute(kAXTitleAttribute, from: child)
                let help: String? = try accessibilityClient.copyAttribute(kAXHelpAttribute, from: child)
                let frame = try readFrame(from: child)
                let processName = application.localizedName ?? application.bundleURL?.deletingPathExtension().lastPathComponent ?? "Unknown"
                let id = MenuBarItemIdentity.makeID(
                    bundleIdentifier: application.bundleIdentifier,
                    processName: processName,
                    title: title,
                    help: help,
                    fallbackIndex: index
                )
                let displayName = firstNonEmpty(title, help, application.localizedName, application.bundleIdentifier) ?? "Untitled"

                let record = MenuBarItemRecord(
                    id: id,
                    bundleIdentifier: application.bundleIdentifier,
                    processName: processName,
                    displayName: displayName,
                    title: title,
                    help: help,
                    lastKnownFrame: frame.map(CodableRect.init)
                )
                proxies.append(MenuBarItemProxy(record: record, application: application, element: child, accessibilityClient: accessibilityClient))
            }
        }

        return proxies
    }

    private func readFrame(from element: AXUIElement) throws -> CGRect? {
        guard let rawPosition: AXValue = try accessibilityClient.copyAttribute(kAXPositionAttribute, from: element),
              let rawSize: AXValue = try accessibilityClient.copyAttribute(kAXSizeAttribute, from: element) else {
            return nil
        }

        var point = CGPoint.zero
        var size = CGSize.zero
        guard AXValueGetValue(rawPosition, .cgPoint, &point),
              AXValueGetValue(rawSize, .cgSize, &size) else {
            return nil
        }
        return CGRect(origin: point, size: size)
    }

    private func firstNonEmpty(_ values: String?...) -> String? {
        values.compactMap { value in
            let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed?.isEmpty == false ? trimmed : nil
        }.first
    }
}
