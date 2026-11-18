import Foundation

/// P9-REMEMBER (D28): what a launch and a quit do with the kept sign-ins, through the two seams. Every log line
/// holds a count or an error kind: never a cookie's name, value or domain.
public final class SignInKeeper {
    public let service: String
    let secrets: SecretStore
    let jar: CookieJar
    let marker: CleanQuitMarker
    let log: (String) -> Void
    /// While the kept cookies are being set: a quit then leaves the item as it is (the next launch restores it).
    private var restoring = false

    public init(secrets: SecretStore, jar: CookieJar, marker: CleanQuitMarker, service: String,
                log: @escaping (String) -> Void) {
        self.secrets = secrets
        self.jar = jar
        self.marker = marker
        self.service = service
        self.log = log
    }

    /// At launch, before the first tab loads: set the kept cookies back, then delete the item. `done` hears how
    /// many came back: 0 after a crash, with the switch off, or for a missing, corrupt or unreadable item.
    public func launch(remember: Bool, done: @escaping (Int) -> Void) {
        let crashed: Bool
        do {
            crashed = try marker.launch()
        } catch {
            crashed = true  // no marker, no proof of a clean quit: nothing comes back
            log("sign-ins: the launch marker could not be written")
        }
        guard !crashed, remember else {
            log(crashed ? "sign-ins: the last run did not quit cleanly, restored 0" : "sign-ins: off, restored 0")
            forget()
            return done(0)
        }
        guard let cookies = kept() else { return done(0) }
        restore(cookies, done: done)
    }

    /// The item's cookies; nil when there is none or it cannot be read. Every nil path deletes too (used once;
    /// an item another signature made is emptied instead, NT-BLD-006).
    private func kept() -> [HTTPCookie]? {
        let bytes: Data?
        do {
            bytes = try secrets.read(service: service)
        } catch {
            log("sign-ins: \(Self.kind(error)), restored 0")
            forget()
            return nil
        }
        guard let bytes, !bytes.isEmpty else {  // empty: emptied by a delete it could not make (NT-BLD-006)
            log("sign-ins: none kept, restored 0")
            forget()
            return nil
        }
        guard let cookies = SignIns.decode(bytes) else {
            log("sign-ins: the item is corrupt, deleted, restored 0")
            forget()
            return nil
        }
        return cookies
    }

    /// Every cookie set into the jar, then the item deleted (used once).
    private func restore(_ cookies: [HTTPCookie], done: @escaping (Int) -> Void) {
        var left = cookies.count
        restoring = left > 0
        let finish = { [self] in
            restoring = false
            forget()
            log("sign-ins: restored \(cookies.count)")
            done(cookies.count)
        }
        guard left > 0 else { return finish() }
        for cookie in cookies {
            jar.set(cookie) {
                left -= 1
                if left == 0 { finish() }
            }
        }
    }

    /// At quit: the switch on, the session cookies become the item (none: no item); off, the item goes.
    public func quit(remember: Bool, done: @escaping (Int) -> Void) {
        guard remember else {
            forget()
            return done(0)
        }
        guard !restoring else {  // the item is still the whole last set: keep it, write nothing half-set
            log("sign-ins: quit while restoring, the item stays")
            return done(0)
        }
        jar.all { [self] cookies in
            let session = SignIns.sessionOnly(cookies)
            do {
                if session.isEmpty {
                    try secrets.delete(service: service)
                } else {
                    try secrets.write(try SignIns.encode(session), service: service)
                }
                log("sign-ins: kept \(session.count)")
                done(session.count)
            } catch {
                log("sign-ins: \(Self.kind(error)), kept 0")
                done(0)
            }
        }
    }

    /// The quit ended cleanly: the next launch may restore.
    public func cleanQuit() {
        do {
            try marker.clear()
        } catch {
            log("sign-ins: the launch marker could not be removed")
        }
    }

    /// No item afterwards (the switch turned off, Clear All). A failure is logged by its kind.
    public func forget() {
        do {
            try secrets.delete(service: service)
        } catch {
            log("sign-ins: \(Self.kind(error)), the item may remain")
        }
    }

    /// An error by its kind only: a Keychain status, or the error's type; never a message that could hold data.
    static func kind(_ error: Error) -> String {
        (error as? SecretsError)?.kind ?? "error \(type(of: error))"
    }
}
