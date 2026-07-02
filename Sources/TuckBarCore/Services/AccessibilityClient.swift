import AppKit
import ApplicationServices

protocol AccessibilityClient {
    var isTrusted: Bool { get }
    func requestTrustPrompt()
    func runningApplications() -> [NSRunningApplication]
    func applicationElement(for processIdentifier: pid_t) -> AXUIElement
    func copyAttribute<T>(_ attribute: String, from element: AXUIElement) throws -> T?
    func performPress(on element: AXUIElement) throws
}

enum AccessibilityError: LocalizedError {
    case attributeReadFailed(attribute: String, code: AXError)
    case actionFailed(action: String, code: AXError)

    var errorDescription: String? {
        switch self {
        case let .attributeReadFailed(attribute, code):
            "Could not read Accessibility attribute \(attribute) (\(code.rawValue))."
        case let .actionFailed(action, code):
            "Could not perform Accessibility action \(action) (\(code.rawValue))."
        }
    }
}

final class SystemAccessibilityClient: AccessibilityClient {
    var isTrusted: Bool {
        AXIsProcessTrusted()
    }

    func requestTrustPrompt() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }

    func runningApplications() -> [NSRunningApplication] {
        NSWorkspace.shared.runningApplications
            .filter { !$0.isTerminated && $0.activationPolicy != .prohibited }
    }

    func applicationElement(for processIdentifier: pid_t) -> AXUIElement {
        AXUIElementCreateApplication(processIdentifier)
    }

    func copyAttribute<T>(_ attribute: String, from element: AXUIElement) throws -> T? {
        var rawValue: CFTypeRef?
        let error = AXUIElementCopyAttributeValue(element, attribute as CFString, &rawValue)
        if error == .attributeUnsupported || error == .noValue {
            return nil
        }
        guard error == .success else {
            throw AccessibilityError.attributeReadFailed(attribute: attribute, code: error)
        }
        return rawValue as? T
    }

    func performPress(on element: AXUIElement) throws {
        let error = AXUIElementPerformAction(element, kAXPressAction as CFString)
        guard error == .success else {
            throw AccessibilityError.actionFailed(action: kAXPressAction, code: error)
        }
    }
}
