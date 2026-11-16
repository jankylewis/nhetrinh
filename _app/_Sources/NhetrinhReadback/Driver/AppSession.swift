import AppKit

/// One running instance of the app under readback. It is started through LaunchServices, like
/// a Dock click, without taking the focus, and in the profile "readback", so the user's own
/// cookies, cache and (later) saved tabs are never touched.
final class AppSession {
    static let installed = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Applications/nhetrinh.app")

    let appURL: URL
    private(set) var pid: pid_t = 0

    init(appURL: URL) { self.appURL = appURL }

    var isRunning: Bool { pid > 0 && kill(pid, 0) == 0 }

    func ensureRunning() throws {
        if !isRunning { try launch() }
    }

    /// Start a fresh instance (the old one is quit first). `env` is added to the launch environment.
    func launch(env: [String: String] = [:]) throws {
        quit()
        let config = NSWorkspace.OpenConfiguration()
        config.createsNewApplicationInstance = true
        config.activates = false
        config.environment = ["NHT_PROFILE": "readback"].merging(env) { _, new in new }
        let done = DispatchSemaphore(value: 0)
        var failure: Error?
        NSWorkspace.shared.openApplication(at: appURL, configuration: config) { app, error in
            self.pid = app?.processIdentifier ?? 0
            failure = error
            done.signal()
        }
        done.wait()
        if let failure { throw StepError.cannotDrive("launch failed: \(failure.localizedDescription)") }
        guard isRunning else { throw StepError.cannotDrive("the app did not start") }
    }

    /// Quit like the user does (terminate request); force it only if the app does not answer.
    func quit() {
        guard isRunning else { return }
        let app = NSRunningApplication(processIdentifier: pid)
        app?.terminate()
        if !waitUntil(5, { !self.isRunning }) {
            app?.forceTerminate()
            waitUntil(3) { !self.isRunning }
        }
        pid = 0
        Thread.sleep(forTimeInterval: 2)  // let WebKit's helper processes exit as well
    }

    // MARK: - What the user sees

    /// Every step that reads or acts on the interface calls this first: without the permission
    /// the step is NOT READ BACK; it must never look like a failure of the app, or like a pass.
    func requireAccessibility() throws {
        guard AXNode.isTrusted else {
            throw StepError.cannotDrive("the terminal app has no Accessibility permission (System Settings)")
        }
    }

    private func root() throws -> AXNode {
        try requireAccessibility()
        try ensureRunning()
        return AXNode.application(pid: pid)
    }

    func window() throws -> AXNode {
        let app = try root()
        var found: AXNode?
        waitUntil(10) {
            found = app.windows.first
            return found != nil
        }
        guard let found else { throw StepError.fail("no window after 10 s") }
        return found
    }

    func element(_ id: String) throws -> AXNode {
        guard let found = try window().find(id: id) else { throw StepError.fail("no element `\(id)` in the window") }
        return found
    }

    func menuItem(_ path: [String]) throws -> AXNode {
        guard let item = try root().menuItem(path) else {
            throw StepError.fail("no menu item \(path.joined(separator: " > "))")
        }
        return item
    }

    func rowCount() throws -> Int { try element("nhetrinh.sidebar").rows.count }
    func addressText() throws -> String { try element("nhetrinh.address").value }

    /// Put `text` in the address field and confirm it, as Return does.
    func navigate(_ text: String) throws {
        let field = try element("nhetrinh.address")
        try field.set(kAXValueAttribute, to: text as CFString)
        try field.confirm()
    }
}
