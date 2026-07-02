import AppKit
import SwiftUI

@MainActor
final class DockIconController: ObservableObject {
    @Published private(set) var isDockIconVisible: Bool

    private let defaults: UserDefaults
    private let key = "isDockIconVisible"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if defaults.object(forKey: key) == nil {
            self.isDockIconVisible = true
            defaults.set(true, forKey: key)
        } else {
            self.isDockIconVisible = defaults.bool(forKey: key)
        }
    }

    func apply() {
        NSApp.setActivationPolicy(isDockIconVisible ? .regular : .accessory)
        if isDockIconVisible {
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    func setDockIconVisible(_ isVisible: Bool) {
        guard isDockIconVisible != isVisible else { return }
        isDockIconVisible = isVisible
        defaults.set(isVisible, forKey: key)
        apply()
    }
}
