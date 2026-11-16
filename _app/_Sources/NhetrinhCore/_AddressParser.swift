import Foundation

/// Address bar input -> URL. Anything that does not look like a URL becomes a search.
public enum AddressParser {
    public static let searchTemplate = "https://www.google.com/search?q="

    public static func url(from raw: String) -> URL? {
        let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return nil }
        if text.contains("://"), let u = URL(string: text) { return u }
        let looksLikeHost = !text.contains(" ")
            && (text.contains(".") || text.hasPrefix("localhost"))
        if looksLikeHost, let u = URL(string: "https://" + text) { return u }
        let q = text.addingPercentEncoding(withAllowedCharacters: queryValueAllowed) ?? text
        return URL(string: searchTemplate + q)
    }

    /// Characters safe inside one query value: '&', '+', '=', '?', '#' must be escaped.
    static let queryValueAllowed: CharacterSet = {
        var set = CharacterSet.urlQueryAllowed
        set.remove(charactersIn: "&+=?#")
        return set
    }()
}
