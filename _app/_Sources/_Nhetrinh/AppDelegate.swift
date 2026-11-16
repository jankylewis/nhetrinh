import AppKit
import NhetrinhCore

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var browser: BrowserWindowController?
    /// Exists only when started with `NHT_READBACK=1` (D23); a normal launch makes no socket.
    private(set) var probe: ProbeServer?
    /// Links from other apps that came before the window (a launch by a link): opened after the session (P5).
    private var incoming: [URL] = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        setDockIcon()
        let browser = BrowserWindowController()
        self.browser = browser
        NSApp.mainMenu = AppMenu.build(browser: browser)
        browser.showWindow(nil)
        browser.openInitialTabs()
        browser.openIncoming(incoming)
        incoming = []
        startProbe(if: ProcessInfo.processInfo.environment, browser)
    }

    /// A link another app hands to nhetrinh (P5): a new tab. macOS brings the app forward itself.
    func application(_ application: NSApplication, open urls: [URL]) {
        guard let browser else { return incoming.append(contentsOf: urls) }
        browser.openIncoming(urls)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }

    /// Quit saves the session at once (P1); the probe's socket goes away.
    func applicationWillTerminate(_ notification: Notification) {
        browser?.saveSession()
        probe?.stop()
    }

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
