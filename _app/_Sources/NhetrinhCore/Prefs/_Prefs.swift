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

    public init() {}

    /// The prefs in `bytes`; nil when they are not a JSON object. A key of the wrong kind or out of
    /// range keeps its default: one bad value never costs the others.
    public static func decode(_ bytes: Data) -> Prefs? {
        guard let object = (try? JSONSerialization.jsonObject(with: bytes)) as? [String: Any] else { return nil }
        if let zoom = object["zoom"], !(zoom is [String: Any]) { return nil }
        var prefs = Prefs()
        for (host, level) in object["zoom"] as? [String: Any] ?? [:] {
            guard let level = level as? Double else { continue }
            prefs.zoom[host] = Zoom.clamp(level)
        }
        prefs.searchEngine = (object["searchEngine"] as? String).flatMap(SearchEngine.init(rawValue:)) ?? .google
        prefs.appearance = (object["appearance"] as? String).flatMap(Appearance.init(rawValue:)) ?? .system
        if let minutes = object["idleUnloadMinutes"] as? Int, minutes >= 1 { prefs.idleUnloadMinutes = minutes }
        return prefs
    }

    public func encoded() throws -> Data {
        let object: [String: Any] = ["zoom": zoom, "searchEngine": searchEngine.rawValue,
                                     "idleUnloadMinutes": idleUnloadMinutes, "appearance": appearance.rawValue]
        return try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys, .prettyPrinted])
    }
}
