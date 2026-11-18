import AppKit
import NhetrinhCore

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var browser: BrowserWindowController?
    /// The window from the launch on; `browser` only once the tabs are open (links queue until then, P5).
    private var launching: BrowserWindowController?
    /// Exists only when started with `NHT_READBACK=1` (D23); a normal launch makes no socket.
    private(set) var probe: ProbeServer?
    /// Links from other apps that came before the window (a launch by a link): opened after the session (P5).
    private var incoming: [URL] = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        Screen.presenter = AppKitScreen()  // before a launch nothing comes on screen (P8-TESTWIN-1)
        SignInSeams.secrets = KeychainSecrets()  // before a launch: in memory (P9-REMEMBER)
        SignInSeams.jar = { WebCookieJar { WebConfig.shared.websiteDataStore.httpCookieStore } }
        setDockIcon()
        let browser = BrowserWindowController()
        AppMenu.install(browser: browser)
        browser.showWindow(nil)
        let env = ProcessInfo.processInfo.environment
        let folder = BrowserWindowController.sessionFolder(env)
        let keeper = BrowserWindowController.signInKeeper(folder: folder, profile: env["NHT_PROFILE"])
        begin(browser, keeper: keeper, remember: BrowserWindowController.remembers(in: folder), env: env)
    }

    /// The kept sign-ins set back, then `open` (P9-REMEMBER).
    func begin(_ browser: BrowserWindowController, keeper: SignInKeeper?, remember: Bool, env: [String: String],
               wait: TimeInterval = BrowserWindowController.signInWait) {
        launching = browser
        browser.restoreSignIns(with: keeper, remember: remember, wait: wait) { [weak self] in
            self?.open(browser, env)
        }
    }

    /// The window a quit keeps the sign-ins through: also before the tabs open, so a quit while the cookies
    /// are still being set is a clean quit that keeps the item (REVIEW_P9_REMEMBER.md defect 5).
    var quitTarget: BrowserWindowController? { browser ?? launching }

    /// After the kept sign-ins are back (P9-REMEMBER): the tabs, the links that came first, the probe.
    private func open(_ browser: BrowserWindowController, _ env: [String: String]) {
        self.browser = browser
        browser.openInitialTabs()
        browser.openIncoming(incoming)
        incoming = []
        startProbe(if: env, browser)
    }

    /// A link another app hands to nhetrinh (P5): a new tab. macOS brings the app forward itself.
    func application(_ application: NSApplication, open urls: [URL]) {
        guard let browser else { return incoming.append(contentsOf: urls) }
        browser.openIncoming(urls)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }

    /// P9-REMEMBER: a quit first keeps the sign-ins (WebKit answers later), then ends.
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        guard let target = quitTarget, target.signIns != nil else { return .terminateNow }
        target.keepSignIns { NSApp.reply(toApplicationShouldTerminate: true) }
        return .terminateLater
    }

    /// Quit saves the session at once (P1) and marks the quit clean (P9-REMEMBER); the probe's socket goes away.
    func applicationWillTerminate(_ notification: Notification) {
        browser?.saveSession()
        quitTarget?.signIns?.cleanQuit()  // no tabs yet: no session saved, the quit still clean
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
