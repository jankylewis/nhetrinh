import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var browser: BrowserWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setDockIcon()
        let browser = BrowserWindowController()
        self.browser = browser
        NSApp.mainMenu = AppMenu.build(browser: browser)
        browser.showWindow(nil)
        browser.openInitialTabs()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }

    /// macOS draws a bundle (.icns) icon on a tile; an image set at runtime is drawn as-is (NT-BLD-001).
    /// AppIcon.png is 256 px: the app keeps decoded copies of it, and 1024 px cost 33 MB (NT-PRF-001).
    private func setDockIcon() {
        guard let url = Bundle.main.url(forResource: "AppIcon", withExtension: "png"),
              let icon = NSImage(contentsOf: url) else {
            Log.app.error("Dock icon: AppIcon.png is missing from the bundle")
            return
        }
        NSApp.applicationIconImage = icon
    }
}
