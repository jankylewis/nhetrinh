import Foundation

// P4 (hubs/product/plan/M2_REAL_SITES_WORK.md, D19); tests in Tests/_NhetrinhCoreTests/Prefs/.

/// The app's look: System follows macOS; Light and Dark set it for nhetrinh and its pages.
public enum Appearance: String, CaseIterable, Sendable {
    case system, light, dark

    public var title: String { rawValue.prefix(1).uppercased() + rawValue.dropFirst() }
}

/// Where words typed in the address bar are searched.
public enum SearchEngine: String, CaseIterable, Sendable {
    case google
    case duckDuckGo = "duckduckgo"
    case bing

    public var title: String {
        switch self {
        case .google: return "Google"
        case .duckDuckGo: return "DuckDuckGo"
        case .bing: return "Bing"
        }
    }

    /// The search address; the escaped words follow it.
    public var template: String {
        switch self {
        case .google: return "https://www.google.com/search?q="
        case .duckDuckGo: return "https://duckduckgo.com/?q="
        case .bing: return "https://www.bing.com/search?q="
        }
    }
}

/// The few settings, saved as `prefs.json` (`PrefsStore`). Every key may be missing: it keeps its default.
public struct Prefs: Equatable, Sendable {
    public static let defaultIdleMinutes = 10
    /// Zoom level per host (`Zoom.hostKey`); a host at 100 % has no entry.
    public var zoom: [String: Double] = [:]
    public var searchEngine = SearchEngine.google
    /// Unload a background tab idle this long (minutes, at least 1).
    public var idleUnloadMinutes = Prefs.defaultIdleMinutes
    public var appearance = Appearance.system
    /// P8-SIDE-1: the side of the window the tab sidebar sits on.
    public var sidebarSide = SidebarSide.left
    /// P9-REMEMBER (D28): keep session cookies (sign-ins) across a quit; a file without the key reads as on.
    public var rememberSignIns = true

    public init() {}

    /// The prefs in `bytes`; nil when they are not a JSON object. A key of the wrong kind or out of
    /// range keeps its default: one bad value never costs the others (F7). A JSON boolean is not a
    /// number (F4); hosts are read lower case, as `Zoom.hostKey` gives them (F10).
    public static func decode(_ bytes: Data) -> Prefs? {
        guard let object = (try? JSONSerialization.jsonObject(with: bytes)) as? [String: Any] else { return nil }
        var prefs = Prefs()
        let zoom = object["zoom"] as? [String: Any] ?? [:]
        for host in zoom.keys.sorted() {  // sorted: two spellings of one host give the same answer every time
            guard let level = number(zoom[host]) else { continue }
            prefs.zoom[host.lowercased()] = Zoom.clamp(level)
        }
        prefs.searchEngine = (object["searchEngine"] as? String).flatMap(SearchEngine.init(rawValue:)) ?? .google
        prefs.appearance = (object["appearance"] as? String).flatMap(Appearance.init(rawValue:)) ?? .system
        prefs.sidebarSide = (object["sidebarSide"] as? String).flatMap(SidebarSide.init(rawValue:)) ?? .left
        prefs.rememberSignIns = flag(object["rememberSignIns"]) ?? true
        if let minutes = number(object["idleUnloadMinutes"]).flatMap(Int.init(exactly:)), minutes >= 1 {
            prefs.idleUnloadMinutes = minutes
        }
        return prefs
    }

    /// A JSON number; nil for anything else, a boolean too (JSONSerialization gives both as NSNumber).
    static func number(_ value: Any?) -> Double? {
        guard let number = value as? NSNumber, CFGetTypeID(number) != CFBooleanGetTypeID() else { return nil }
        return number.doubleValue
    }

    /// A JSON boolean; nil for anything else, a number too.
    static func flag(_ value: Any?) -> Bool? {
        guard let number = value as? NSNumber, CFGetTypeID(number) == CFBooleanGetTypeID() else { return nil }
        return number.boolValue
    }

    /// Clear All (F6 ruling): the per-site settings go (the zoom per host); the app-wide ones stay.
    public mutating func forgetSites() { zoom = [:] }

    public func encoded() throws -> Data {
        let object: [String: Any] = ["zoom": zoom, "searchEngine": searchEngine.rawValue,
                                     "idleUnloadMinutes": idleUnloadMinutes, "appearance": appearance.rawValue,
                                     "sidebarSide": sidebarSide.rawValue, "rememberSignIns": rememberSignIns]
        return try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys, .prettyPrinted])
    }
}
