import AppKit

/// One running instance of the app under readback. It is started through LaunchServices, like
/// a Dock click, without taking the focus, and in the profile "readback", so the user's own
/// cookies, cache and (later) saved tabs are never touched.
final class AppSession {
    static let installed = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Applications/nhetrinh.app")

    let appURL: URL
    private(set) var pid: pid_t = 0
    /// R2 keeps its capture here (`--keep-capture`); nil: the capture is deleted at once.
    var keepCapture: URL?

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
            throw StepError.cannotDrive(Grant.noAccessibility())
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

    /// Select the sidebar row `fromEnd` places above the last, as a click does. The rows are read
    /// fresh right before acting and again for the one retry, never kept (NT-GAT-006).
    func selectRow(fromEnd offset: Int) throws {
        try Fresh.retryingOnce {
            let rows = try element("nhetrinh.sidebar").rows
            guard let index = Fresh.rowIndex(fromEnd: offset, count: rows.count) else {
                throw StepError.fail("the sidebar has \(rows.count) row(s); \(offset + 1) are needed")
            }
            try rows[index].set(kAXSelectedAttribute, to: kCFBooleanTrue)
        }
    }

    /// Put `text` in the address field and confirm it, as Return does.
    func navigate(_ text: String) throws {
        let field = try element("nhetrinh.address")
        try field.set(kAXValueAttribute, to: text as CFString)
        try field.confirm()
    }
}

/// macOS grants Accessibility and Screen Recording per app (NT-TG-003). A step without a grant is
/// NOT READ BACK, and its reason names the app that lacks it: nhetrinh-readback.app when the tool
/// runs as that app (readback_app.sh run), else the terminal that started it. A name, never a path.
enum Grant {
    static func grantee(bundlePath: String = Bundle.main.bundlePath) -> String {
        let bundle = URL(fileURLWithPath: bundlePath)
        return bundle.pathExtension == "app" ? bundle.lastPathComponent : "the terminal app"
    }

    static func noAccessibility(bundlePath: String = Bundle.main.bundlePath) -> String {
        grantee(bundlePath: bundlePath) + " has no Accessibility permission (System Settings, Privacy & Security)"
    }

    static func noScreenRecording(bundlePath: String = Bundle.main.bundlePath) -> String {
        grantee(bundlePath: bundlePath) + " has no Screen Recording permission (System Settings, Privacy & Security)"
    }
}
