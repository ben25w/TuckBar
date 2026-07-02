import AppKit
import SwiftUI

@MainActor
final class StatusBarCoordinator: NSObject {
    private let store: IconRegistryStore
    private let scanner: MenuBarScanning
    private let accessibilityClient: AccessibilityClient
    private let visibilityController: IconVisibilityControlling
    private let dockIconController: DockIconController
    private let statusItem: NSStatusItem
    private var panel: NSPanel?
    private var scanTimer: Timer?
    private var proxiesByID: [String: MenuBarItemProxy] = [:]

    init(
        store: IconRegistryStore,
        scanner: MenuBarScanning,
        accessibilityClient: AccessibilityClient,
        visibilityController: IconVisibilityControlling,
        dockIconController: DockIconController
    ) {
        self.store = store
        self.scanner = scanner
        self.accessibilityClient = accessibilityClient
        self.visibilityController = visibilityController
        self.dockIconController = dockIconController
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        super.init()
    }

    func start() {
        dockIconController.apply()
        configureStatusItem()
        store.load()
        refresh()
        scanTimer = Timer.scheduledTimer(withTimeInterval: 8.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refresh()
            }
        }
    }

    func stop() {
        scanTimer?.invalidate()
        store.save()
    }

    private func configureStatusItem() {
        guard let button = statusItem.button else { return }
        button.image = StatusIconFactory.statusItemImage()
        button.image?.isTemplate = true
        button.toolTip = "TuckBar"
        button.target = self
        button.action = #selector(togglePanel)
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }

    @objc private func togglePanel() {
        if panel?.isVisible == true {
            panel?.orderOut(nil)
        } else {
            showPanel()
        }
    }

    private func showPanel() {
        if panel == nil {
            panel = makePanel()
        }

        guard let panel, let button = statusItem.button, let window = button.window else { return }
        let buttonFrame = button.convert(button.bounds, to: nil)
        let screenFrame = window.convertToScreen(buttonFrame)
        let panelSize = panel.frame.size
        let screen = NSScreen.screen(containing: screenFrame) ?? window.screen ?? NSScreen.main
        let visibleFrame = screen?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let margin: CGFloat = 8
        let x = (screenFrame.midX - panelSize.width / 2)
            .clamped(to: visibleFrame.minX + margin ... visibleFrame.maxX - panelSize.width - margin)
        let y = (screenFrame.minY - panelSize.height - margin)
            .clamped(to: visibleFrame.minY + margin ... visibleFrame.maxY - panelSize.height - margin)

        panel.setFrameOrigin(NSPoint(x: x, y: y))
        panel.orderFrontRegardless()
        NSApp.activate(ignoringOtherApps: true)
    }

    private func makePanel() -> NSPanel {
        let view = VirtualShelfView(
            store: store,
            dockIconController: dockIconController,
            hasAccessibilityPermission: accessibilityClient.isTrusted,
            onRefresh: { [weak self] in self?.refresh() },
            onRequestPermission: { [weak self] in self?.requestAccessibilityPermission() },
            onPress: { [weak self] id in self?.pressItem(withID: id) },
            onQuit: { NSApp.terminate(nil) }
        )
        let hostingView = NSHostingView(rootView: view)
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 460),
            styleMask: [.nonactivatingPanel, .titled, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = true
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.contentView = hostingView
        return panel
    }

    private func refresh() {
        guard accessibilityClient.isTrusted else {
            store.markAllUnavailable()
            return
        }

        do {
            let proxies = try scanner.scan()
            proxiesByID = Dictionary(uniqueKeysWithValues: proxies.map { ($0.record.id, $0) })
            store.merge(scannedRecords: proxies.map(\.record))
            applyVisibilityPreferences()
        } catch {
            store.lastScanError = error.localizedDescription
        }
    }

    private func applyVisibilityPreferences() {
        for record in store.records where record.placementMode == .virtualMenu {
            let result = visibilityController.apply(mode: .virtualMenu, to: record)
            if result == .virtualOnlyUnsupported {
                store.updateHideSupportStatus(.virtualOnlyUnsupported, for: record.id)
            }
        }
    }

    private func pressItem(withID id: String) {
        guard let proxy = proxiesByID[id] else { return }
        do {
            try proxy.press()
        } catch {
            store.lastScanError = error.localizedDescription
        }
    }

    private func requestAccessibilityPermission() {
        accessibilityClient.requestTrustPrompt()
    }
}

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

private extension NSScreen {
    static func screen(containing rect: NSRect) -> NSScreen? {
        let center = NSPoint(x: rect.midX, y: rect.midY)
        return screens.first { $0.frame.contains(center) }
    }
}
