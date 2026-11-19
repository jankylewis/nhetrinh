import Foundation
import NhetrinhCore
import Security
import WebKit

/// P9-REMEMBER (D28): the seams of Remember sign-ins. Before a launch, which is every unit test, they are in
/// memory (`HeldSecrets`, `HeldJar`): no test reaches the Keychain or a cookie store. `AppDelegate` sets the
/// Keychain and the shared data store's cookies first thing at launch, as it sets `Screen.presenter`.
@MainActor
enum SignInSeams {
    static var secrets: SecretStore = HeldSecrets()
    static var jar: () -> CookieJar = { HeldJar() }
}

/// The login Keychain: ONE generic-password item per profile and signing kind (service per profile, account
/// `signins.signed` or `signins.adhoc`), never synchronized, so a new build signed by the same identity reads what
/// the last one kept (`_build.sh` signs with the local identity of `signing.sh` when it exists). An item another
/// signature made can be neither read nor deleted, only overwritten (NT-BLD-006): an ad-hoc build and a signed one
/// therefore never share an item; a write updates in place, a refused delete empties the item. Every call runs
/// with user interaction off: one that would ask fails at once with its status. Outside the launched app it
/// refuses with no Keychain call, whatever a caller passes (guard test).
final class KeychainSecrets: SecretStore {
    static let appBundleID = "io.github.jankylewis.nhetrinh"
    /// The account of a build's signing kind: an item first kept ad hoc is unreadable by a signed build forever.
    static func account(adHoc: Bool) -> String { adHoc ? "signins.adhoc" : "signins.signed" }
    /// The account of the builds before the split: a signed build reads it once, then deletes it, so an update
    /// keeps the sign-ins the build before it kept (no sign-in again after the install).
    static let oldAccount = "signins"
    /// How many in this process can reach the Keychain: 0 in every unit test (guard test).
    private(set) static var reachable = 0
    let calls: KeychainCalls

    init(calls: KeychainCalls = SecurityCalls()) {
        self.calls = calls
        if calls is SecurityCalls, calls.reachesKeychain { Self.reachable += 1 }
    }

    /// Only the app itself reaches the Keychain or its cookie store.
    static func allowed(_ bundleID: String?) -> Bool { bundleID == appBundleID }

    /// `body` with user interaction off, then the setting as it was (main thread only).
    private func quietly<T>(_ body: () -> T) -> T {
        let before = calls.interactionAllowed
        calls.interactionAllowed = false
        defer { calls.interactionAllowed = before }
        return body()
    }

    private func query(_ service: String, account: String? = nil) throws -> [String: Any] {
        guard calls.reachesKeychain else { throw SecretsError.notLaunched }
        return [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: service,
                kSecAttrAccount as String: account ?? Self.account(adHoc: calls.adHoc)]
    }

    /// This build's item; none, and signed: the old account's item once (read, then deleted). An old item this
    /// build may not read (an ad-hoc build's, NT-BLD-006) counts as none.
    func read(service: String) throws -> Data? {
        if let data = try copy(service) { return data }
        guard !calls.adHoc, let old = (try? copy(service, account: Self.oldAccount)) ?? nil else { return nil }
        deleteOld(service)
        return old
    }

    private func copy(_ service: String, account: String? = nil) throws -> Data? {
        var match = try query(service, account: account)
        match[kSecReturnData as String] = true
        match[kSecMatchLimit as String] = kSecMatchLimitOne
        let (status, data) = quietly { calls.copy(match) }
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess else { throw SecretsError.status(status) }
        return data
    }

    /// The item updated in place; added only when there is none.
    func write(_ data: Data, service: String) throws {
        let match = try query(service)
        let status = quietly { () -> OSStatus in
            let updated = calls.update(match, to: [kSecValueData as String: data])
            guard updated == errSecItemNotFound else { return updated }
            var item = match
            item[kSecValueData as String] = data
            item[kSecAttrLabel as String] = "nhetrinh sign-ins"
            return calls.add(item)
        }
        guard status == errSecSuccess else { throw SecretsError.status(status) }
    }

    /// The item deleted; one this signature may not delete is emptied in place (read as none kept).
    func delete(service: String) throws {
        let match = try query(service)
        let status = quietly { () -> OSStatus in
            let deleted = calls.delete(match)
            guard deleted == errSecInvalidOwnerEdit else { return deleted }
            return calls.update(match, to: [kSecValueData as String: Data()])
        }
        guard status == errSecSuccess || status == errSecItemNotFound else { throw SecretsError.status(status) }
        if !calls.adHoc { deleteOld(service) }
    }

    /// The old account's item gone, if this build may delete it; any other answer leaves it (best effort).
    private func deleteOld(_ service: String) {
        guard let match = try? query(service, account: Self.oldAccount) else { return }
        _ = quietly { calls.delete(match) }
    }
}

/// The shared data store's cookies (`WebConfig`): WebKit answers on the main queue. Outside the launched app
/// it refuses as the Keychain does: the store is never even asked for, `all` hears none, `set` sets nothing.
final class WebCookieJar: CookieJar {
    /// How many in this process can reach a cookie store: 0 in every unit test (guard test).
    private(set) static var reachable = 0
    private let store: (() -> WKHTTPCookieStore)?

    init(_ store: @escaping () -> WKHTTPCookieStore) {
        let allowed = KeychainSecrets.allowed(Bundle.main.bundleIdentifier)
        self.store = allowed ? store : nil
        if allowed { Self.reachable += 1 }
    }

    func all(_ done: @escaping ([HTTPCookie]) -> Void) {
        guard let store else { return done([]) }
        store().getAllCookies(done)
    }

    func set(_ cookie: HTTPCookie, _ done: @escaping () -> Void) {
        guard let store else { return done() }
        store().setCookie(cookie, completionHandler: done)
    }
}
