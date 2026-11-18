import Foundation

// P9-REMEMBER (D28): the two seams of Remember sign-ins. In the app they are a Keychain item and the web data
// store's cookies (set at launch, like `Screen`); before a launch, which is every unit test, they are the
// in-memory `HeldSecrets` and `HeldJar`: no test reaches the Keychain or a cookie store.

/// One secret item per `service`.
public protocol SecretStore: AnyObject {
    /// The item's bytes; nil when there is none.
    func read(service: String) throws -> Data?
    /// The item becomes `data`, replacing any older one.
    func write(_ data: Data, service: String) throws
    /// No item afterwards; deleting a missing item is no error.
    func delete(service: String) throws
}

/// The cookies of a data store. Both calls answer on the main queue.
public protocol CookieJar: AnyObject {
    func all(_ done: @escaping ([HTTPCookie]) -> Void)
    func set(_ cookie: HTTPCookie, _ done: @escaping () -> Void)
}

/// Why a secret store refused; logged as its kind only, never with the item's contents.
public enum SecretsError: Error, Equatable {
    /// The Keychain's own status code.
    case status(Int32)
    /// The real Keychain seam was reached outside the launched app (a unit test).
    case notLaunched

    public var kind: String {
        switch self {
        case .status(let code): return "keychain status \(code)"
        case .notLaunched: return "keychain refused outside the app"
        }
    }
}

/// In memory: the seam before a launch. `failure`, when set, is thrown by every call.
public final class HeldSecrets: SecretStore {
    public var items: [String: Data] = [:]
    public var failure: SecretsError?
    /// How many deletes were asked for, even of a missing item.
    public private(set) var deletes = 0

    public init() {}

    public func read(service: String) throws -> Data? {
        if let failure { throw failure }
        return items[service]
    }

    public func write(_ data: Data, service: String) throws {
        if let failure { throw failure }
        items[service] = data
    }

    public func delete(service: String) throws {
        deletes += 1
        if let failure { throw failure }
        items[service] = nil
    }
}

/// In memory: the cookie seam before a launch. Answers at once.
public final class HeldJar: CookieJar {
    public var cookies: [HTTPCookie] = []

    public init() {}

    public func all(_ done: @escaping ([HTTPCookie]) -> Void) { done(cookies) }

    public func set(_ cookie: HTTPCookie, _ done: @escaping () -> Void) {
        cookies.removeAll { $0.name == cookie.name && $0.domain == cookie.domain && $0.path == cookie.path }
        cookies.append(cookie)
        done()
    }
}
