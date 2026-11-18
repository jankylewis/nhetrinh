import Foundation

// P9-REMEMBER (D28); tests in Tests/_NhetrinhCoreTests/Prefs/SignIns/.

/// Remember sign-ins: WebKit writes dated cookies to disk but never a session cookie (no expiry), so a site's
/// sign-in held in one is gone after a quit. At a clean quit the session cookies are kept as ONE Keychain item
/// per profile, set back before the first tab loads at the next launch, and the item deleted (used once).
public enum SignIns {
    public static let servicePrefix = "io.github.jankylewis.nhetrinh.signins."

    /// The Keychain service of `profile` (`NHT_PROFILE`); nil or empty: `default`.
    public static func service(profile: String?) -> String {
        let name = profile ?? ""
        return servicePrefix + (name.isEmpty ? "default" : name)
    }

    /// The cookies a quit keeps: session cookies only. Dated ones WebKit keeps itself.
    public static func sessionOnly(_ cookies: [HTTPCookie]) -> [HTTPCookie] {
        cookies.filter(\.isSessionOnly)
    }

    /// The item's bytes for `cookies`.
    public static func encode(_ cookies: [HTTPCookie]) throws -> Data {
        let item = SignInItem(version: SignInItem.current, cookies: cookies.map(SavedCookie.init))
        return try JSONEncoder().encode(item)
    }

    /// The cookies in an item's bytes; nil when they are not an item (corrupt).
    public static func decode(_ bytes: Data) -> [HTTPCookie]? {
        let item = try? JSONDecoder().decode(SignInItem.self, from: bytes)
        guard let item, item.version == SignInItem.current else { return nil }
        return item.cookies.compactMap(\.cookie)
    }
}

/// The item: a version, then the cookies. Only what a session cookie needs to work again (it has no expiry).
struct SignInItem: Codable {
    static let current = 1
    let version: Int
    let cookies: [SavedCookie]
}

struct SavedCookie: Codable {
    static let httpOnlyKey = HTTPCookiePropertyKey("HttpOnly")
    let name, value, domain, path: String
    let secure, httpOnly: Bool
    let sameSite: String?

    init(_ cookie: HTTPCookie) {
        (name, value, domain, path) = (cookie.name, cookie.value, cookie.domain, cookie.path)
        (secure, httpOnly, sameSite) = (cookie.isSecure, cookie.isHTTPOnly, cookie.sameSitePolicy?.rawValue)
    }

    /// The cookie again; nil when Foundation refuses its properties.
    var cookie: HTTPCookie? {
        var properties: [HTTPCookiePropertyKey: Any] = [.name: name, .value: value, .domain: domain, .path: path]
        if secure { properties[.secure] = "TRUE" }
        if httpOnly { properties[Self.httpOnlyKey] = "TRUE" }
        if let sameSite { properties[.sameSitePolicy] = sameSite }
        return HTTPCookie(properties: properties)
    }
}
