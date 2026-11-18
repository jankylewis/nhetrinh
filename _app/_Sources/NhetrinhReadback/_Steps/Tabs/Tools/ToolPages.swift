import Foundation

/// The P4 pages (hubs/product/plan/M2_REAL_SITES_WORK.md, R27-R30a); each sets its title to what it saw:
///   /find          the word "Example" for the find bar (R27)
///   /cookie/set    sets the cookie `nhetrinh=readback` for an hour: "cookie: set" (R30)
///   /cookie/read   "cookie: nhetrinh=readback", or "cookie: none" (R30)
///   /cookie/session       sets the session cookie (no expiry) `nhetrinh_signin=readback`: "session: set" (R51)
///   /cookie/session/read  "session: readback", or "session: none" (R51)
///   /scheme        `prefers-color-scheme`, and its changes: "scheme: dark", "scheme: light" (R30a)
enum ToolPages {
    static let findTitle = "find test"
    static let cookieSetTitle = "cookie: set"
    static let cookieTitle = "cookie: nhetrinh=readback"
    static let noCookieTitle = "cookie: none"
    static let sessionSetTitle = "session: set"

    /// What /cookie/session/read shows: whether the session cookie is there (R51).
    static func sessionTitle(kept: Bool) -> String { "session: \(kept ? "readback" : "none")" }

    static func schemeTitle(dark: Bool) -> String { "scheme: \(dark ? "dark" : "light")" }

    static func reply(path: String) -> TestPageContent.Reply? {
        switch path {
        case "/find": return TestPageContent.html("<title>\(findTitle)</title><p>Example words for the find bar</p>")
        case "/cookie/set":
            return script("document.cookie = 'nhetrinh=readback; max-age=3600; path=/'; "
                + "document.title = '\(cookieSetTitle)'")
        case "/cookie/read": return script("document.title = 'cookie: ' + (document.cookie || 'none')")
        case "/cookie/session":
            return script("document.cookie = 'nhetrinh_signin=readback; path=/'; document.title = '\(sessionSetTitle)'")
        case "/cookie/session/read":
            return script("const kept = document.cookie.split('; ').includes('nhetrinh_signin=readback'); "
                + "document.title = 'session: ' + (kept ? 'readback' : 'none')")
        case "/scheme":
            return script("const m = matchMedia('(prefers-color-scheme: dark)'); "
                + "const show = () => { document.title = 'scheme: ' + (m.matches ? 'dark' : 'light') }; "
                + "show(); m.addEventListener('change', show)")
        default: return nil
        }
    }

    private static func script(_ code: String) -> TestPageContent.Reply {
        TestPageContent.html("<title>tool test</title><p>tool test</p><script>\(code)</script>")
    }
}
