import AppKit
import NhetrinhCore

/// One running instance of the app under readback. It is started through LaunchServices, like
/// a Dock click, without taking the focus, and in the profile "readback", so the user's own
/// cookies, cache and (later) saved tabs are never touched.
final class AppSession {
    static let installed = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Applications/nhetrinh.app")
    /// The app runs in this profile (NHT_PROFILE): its own cookies, cache and saved session.
    static let profile = "readback"

    let appURL: URL
    private(set) var pid: pid_t = 0
    /// Whether the running instance was started with the probe on.
    private(set) var probing = false
    /// R2 keeps its capture here (`--keep-capture`); nil: the capture is deleted at once.
    var keepCapture: URL?
    /// D25: R26a and R26b may bring the app to the front (`--allow-focus`).
    var allowFocus = false
    /// P8, R44: the released zip's URL, from `--release-url`; nil: R44 does not run.
    var releaseURL: URL?

    init(appURL: URL) { self.appURL = appURL }

    var isRunning: Bool { pid > 0 && kill(pid, 0) == 0 }

    func ensureRunning() throws {
        if !isRunning { try launch() }
    }

    /// Start a fresh instance (the old one is quit first). `env` is added to the launch environment;
    /// `probe` adds `NHT_READBACK=1`, so the app answers the readback probe (D23). R8 never asks
    /// for it: the budget is measured on a normal launch.
    func launch(env: [String: String] = [:], probe: Bool = false) throws {
        quit()
        let config = NSWorkspace.OpenConfiguration()
        config.createsNewApplicationInstance = true
        config.activates = false
        let base = ["NHT_PROFILE": Self.profile].merging(probe ? [ProbePath.variable: "1"] : [:]) { _, new in new }
        config.environment = base.merging(env) { _, new in new }
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
        probing = probe
    }

    /// Quit like the user does (terminate request) and wait for the exit; past 5 s, end only the
    /// instance this readback launched, by its pid (NT-TG-004). Returns how it ended, for the report.
    @discardableResult
    func quit() -> QuitOutcome {
        let target = pid
        let outcome = Ending.end(target, isRunning: { self.isRunning }, askToQuit: {
            NSRunningApplication(processIdentifier: target)?.terminate()
        }, kill: { _ = kill($0, SIGKILL) }, wait: { waitUntil($0, $1) })
        guard outcome != .notRunning else { return outcome }
        pid = 0
        probing = false
        Thread.sleep(forTimeInterval: 2)  // let WebKit's helper processes exit as well
        return outcome
    }

    /// The app ended by itself (its own Quit, or a kill): wait up to `timeout`, then forget it.
    func waitForEnd(_ timeout: TimeInterval) -> Bool {
        guard waitUntil(timeout, { !self.isRunning }) else { return false }
        pid = 0
        probing = false
        Thread.sleep(forTimeInterval: 2)  // let WebKit's helper processes exit as well
        return true
    }

    /// Signal 9, as a crash or a power cut does: the app saves nothing more.
    func killNow() {
        if isRunning { kill(pid, SIGKILL) }
    }

    /// A step that reads the system through Accessibility (R2, the Dock) calls this first: without
    /// the permission it is NOT READ BACK; never a failure of the app, never a pass.
    func requireAccessibility() throws {
        guard AXNode.isTrusted else {
            throw StepError.cannotDrive(Grant.noAccessibility())
        }
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

/// How the readback's own app instance ended at a quit (NT-TG-004: one outlived its run).
enum QuitOutcome: Equatable {
    case notRunning
    case quit
    case killed(pid_t)
    case survived(pid_t)

    var line: String {
        switch self {
        case .notRunning: return "end: the app was not running"
        case .quit: return "end: the app quit when asked"
        case .killed(let pid): return "end: the app did not quit within 5 s; the readback ended its own instance "
            + "(pid \(pid), signal 9)"
        case .survived(let pid): return "end: the app still runs after quit and signal 9 (pid \(pid))"
        }
    }
}

/// Ask to quit, wait 5 s; past that, signal 9 to `pid` only (the instance the readback launched).
enum Ending {
    static func end(_ pid: pid_t, isRunning: @escaping () -> Bool, askToQuit: () -> Void, kill: (pid_t) -> Void,
                    wait: (TimeInterval, () -> Bool) -> Bool) -> QuitOutcome {
        guard pid > 0, isRunning() else { return .notRunning }
        askToQuit()
        if wait(5, { !isRunning() }) { return .quit }
        kill(pid)
        return wait(3, { !isRunning() }) ? .killed(pid) : .survived(pid)
    }
}
