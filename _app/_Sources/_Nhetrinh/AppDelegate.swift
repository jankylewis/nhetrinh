import AppKit
import NhetrinhCore

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var browser: BrowserWindowController?
    /// Exists only when started with `NHT_READBACK=1` (D23); a normal launch makes no socket.
    private(set) var probe: ProbeServer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setDockIcon()
        let browser = BrowserWindowController()
        self.browser = browser
        NSApp.mainMenu = AppMenu.build(browser: browser)
        browser.showWindow(nil)
        browser.openInitialTabs()
        startProbe(if: ProcessInfo.processInfo.environment, browser)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }

    func applicationWillTerminate(_ notification: Notification) { probe?.stop() }

    /// The only way the probe starts: `env` (the launch environment) holds `NHT_READBACK=1` (D23).
    func startProbe(if env: [String: String], _ browser: BrowserWindowController) {
        guard ProbePath.isOn(env) else { return }
        do {
            probe = try ProbeServer(folder: ProbePath.folder(pid: getpid()), queue: .main) { [weak browser] in
                browser?.probeAnswer($0) ?? .failed("the browser window is gone")
            }
            Log.app.info("readback probe on (NHT_READBACK=1)")
        } catch {
            Log.app.error("readback probe could not start: \(String(describing: error), privacy: .public)")
        }
    }

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
