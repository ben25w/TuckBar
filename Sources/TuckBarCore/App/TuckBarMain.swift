import AppKit

public enum TuckBarApplication {
    public static func run() {
        let application = NSApplication.shared
        let delegate = AppDelegate()
        application.delegate = delegate
        application.setActivationPolicy(.accessory)
        application.run()
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var coordinator: StatusBarCoordinator?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let accessibility = SystemAccessibilityClient()
        let store = IconRegistryStore()
        let scanner = MenuBarScanner(accessibilityClient: accessibility)
        let visibility = IconVisibilityController()

        coordinator = StatusBarCoordinator(
            store: store,
            scanner: scanner,
            accessibilityClient: accessibility,
            visibilityController: visibility
        )
        coordinator?.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        coordinator?.stop()
    }
}
