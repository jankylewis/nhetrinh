import AppKit
import NhetrinhCore

/// P9-REMEMBER (D28): Remember sign-ins, wired. At launch the kept session cookies are set back before the
/// first tab loads (`AppDelegate` opens the tabs in `then`); at quit they are kept; a clean quit clears the
/// crash marker. The logic and its tests are `NhetrinhCore`'s `SignInKeeper`; the seams are `SignInSeams`.
extension BrowserWindowController {
    /// The longest a launch waits for WebKit before the tabs open anyway; the same for a quit.
    static let signInWait: TimeInterval = 3

    /// This launch's keeper on the seams: none without a session folder (a measurement run).
    static func signInKeeper(folder: URL?, profile: String?) -> SignInKeeper? {
        guard let folder else { return nil }
        let marker = CleanQuitMarker(folder: folder)
        return SignInKeeper(secrets: SignInSeams.secrets, jar: SignInSeams.jar(), marker: marker,
                            service: SignIns.service(profile: profile)) { line in
            Log.app.info("\(line, privacy: .public)")  // counts and error kinds only (SignInKeeper)
        }
    }

    /// The switch as `prefs.json` in `folder` holds it, read without touching the file (`loadPrefs` reports a
    /// bad one later); no file or a bad one: on.
    static func remembers(in folder: URL?) -> Bool {
        guard let folder, let bytes = try? Data(contentsOf: folder.appendingPathComponent(PrefsStore.fileName)),
              let prefs = Prefs.decode(bytes) else { return true }
        return prefs.rememberSignIns
    }

    /// At launch: `keeper` sets the kept cookies back, then `then` runs once (at the latest after `wait`).
    func restoreSignIns(with keeper: SignInKeeper?, remember: Bool, wait: TimeInterval = signInWait,
                        then: @escaping () -> Void) {
        signIns = keeper
        guard let keeper else { return then() }
        let once = Self.once(then)
        DispatchQueue.main.asyncAfter(deadline: .now() + wait) {
            if once() { Log.app.error("sign-ins: not restored within \(wait, privacy: .public) s; tabs opened") }
        }
        keeper.launch(remember: remember) { _ in _ = once() }
    }

    /// At quit: the session cookies kept (the switch on), then `then` once (at the latest after `wait`).
    func keepSignIns(wait: TimeInterval = signInWait, then: @escaping () -> Void) {
        guard let signIns else { return then() }
        let once = Self.once(then)
        DispatchQueue.main.asyncAfter(deadline: .now() + wait) {
            if once() { Log.app.error("sign-ins: not kept within \(wait, privacy: .public) s; quitting") }
        }
        signIns.quit(remember: prefs.rememberSignIns) { _ in _ = once() }
    }

    /// `action` run on the first call only; each call says whether it was the one that ran it.
    private static func once(_ action: @escaping () -> Void) -> () -> Bool {
        var done = false
        return {
            guard !done else { return false }
            done = true
            action()
            return true
        }
    }
}
