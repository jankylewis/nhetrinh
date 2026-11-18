import Foundation
@testable import NhetrinhCore

// P9-REMEMBER: synthetic cookies (example.test, fake-1) and a keeper on the in-memory seams. Nothing here
// reaches the Keychain, a cookie store or the app's own folder: the marker lives in a temporary folder.

func fakeCookie(_ name: String, session: Bool, secure: Bool = false, httpOnly: Bool = false) -> HTTPCookie? {
    var properties: [HTTPCookiePropertyKey: Any] = [.name: name, .value: "fake-1", .domain: "example.test", .path: "/"]
    if !session { properties[.expires] = Date().addingTimeInterval(3600) }
    if secure { properties[.secure] = "TRUE" }
    if httpOnly { properties[HTTPCookiePropertyKey("HttpOnly")] = "TRUE" }
    return HTTPCookie(properties: properties)
}

func fakeCookies(session: Int, dated: Int) -> [HTTPCookie] {
    (0..<session).compactMap { fakeCookie("s\($0)", session: true) }
        + (0..<dated).compactMap { fakeCookie("d\($0)", session: false) }
}

func tempFolder() throws -> URL {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("signins-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
}

/// A keeper on held seams; `lines` collects what it logs.
final class Rig {
    let secrets = HeldSecrets()
    let jar = HeldJar()
    let folder: URL
    var lines: [String] = []
    let service = SignIns.service(profile: "rig")

    init(folder: URL? = nil) throws {
        self.folder = try folder ?? tempFolder()
    }

    /// A new keeper each time, as each launch of the app makes one; `jar` replaces the held one.
    func keeper(jar: CookieJar? = nil) -> SignInKeeper {
        SignInKeeper(secrets: secrets, jar: jar ?? self.jar, marker: CleanQuitMarker(folder: folder),
                     service: service) {
            [weak self] line in self?.lines.append(line)
        }
    }

    var item: Data? { secrets.items[service] }

    /// The count `run` gives its `done`; -1 when `done` was never called.
    func count(_ run: (@escaping (Int) -> Void) -> Void) -> Int {
        var heard = -1
        run { heard = $0 }
        return heard
    }
}

/// A WebKit still setting the kept cookies: it answers `all` (what a page set meanwhile), never `set`.
final class PendingJar: CookieJar {
    var cookies: [HTTPCookie] = []
    func all(_ done: @escaping ([HTTPCookie]) -> Void) { done(cookies) }
    func set(_ cookie: HTTPCookie, _ done: @escaping () -> Void) {}
}
