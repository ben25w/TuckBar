import AppKit
import ApplicationServices

final class MenuBarItemProxy {
    let record: MenuBarItemRecord
    let application: NSRunningApplication
    private let element: AXUIElement
    private let accessibilityClient: AccessibilityClient

    init(record: MenuBarItemRecord, application: NSRunningApplication, element: AXUIElement, accessibilityClient: AccessibilityClient) {
        self.record = record
        self.application = application
        self.element = element
        self.accessibilityClient = accessibilityClient
    }

    func press() throws {
        try accessibilityClient.performPress(on: element)
    }
}
