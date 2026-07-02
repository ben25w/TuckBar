import AppKit

public enum TuckBarApplication {
    private static var delegate: AppDelegate?

    @MainActor
    public static func run() {
        let application = NSApplication.shared
        let delegate = AppDelegate()
        Self.delegate = delegate
        application.delegate = delegate
        application.setActivationPolicy(.regular)
        application.run()
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var coordinator: StatusBarCoordinator?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let accessibility = SystemAccessibilityClient()
        let store = IconRegistryStore()
        let scanner = MenuBarScanner(accessibilityClient: accessibility)
        let visibility = IconVisibilityController()
        let dockIconController = DockIconController()

        coordinator = StatusBarCoordinator(
            store: store,
            scanner: scanner,
            accessibilityClient: accessibility,
            visibilityController: visibility,
            dockIconController: dockIconController
        )
        coordinator?.start()
        configureMainMenu()
        coordinator?.showSettings()
    }

    func applicationWillTerminate(_ notification: Notification) {
        coordinator?.stop()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        coordinator?.showSettings()
        return false
    }

    @objc private func showSettings() {
        coordinator?.showSettings()
    }

    @objc private func showShelf() {
        coordinator?.showPanel()
    }

    @objc private func refreshItems() {
        coordinator?.refresh()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    private func configureMainMenu() {
        let mainMenu = NSMenu()
        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu(title: "TuckBar")

        appMenu.addItem(withTitle: "Settings...", action: #selector(showSettings), keyEquivalent: ",").target = self
        appMenu.addItem(withTitle: "Show Shelf", action: #selector(showShelf), keyEquivalent: "s").target = self
        appMenu.addItem(withTitle: "Refresh Items", action: #selector(refreshItems), keyEquivalent: "r").target = self
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Quit TuckBar", action: #selector(quit), keyEquivalent: "q").target = self

        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)
        NSApp.mainMenu = mainMenu
    }
}
