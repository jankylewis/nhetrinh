import Foundation

// P11-HISTORY (D30); tests in Tests/_NhetrinhCoreTests/_Navigation/_Address/History/HistoryMatchTests.swift.

/// A page the store keeps, as the dropdown reads it.
public struct HistoryEntry: Equatable, Sendable {
    public var url: String
    public var title: String
    public var visits: Int
    public var typed: Int
    public var lastVisit: Date

    public init(url: String, title: String, visits: Int, typed: Int, lastVisit: Date) {
        (self.url, self.title, self.visits, self.typed, self.lastVisit) = (url, title, visits, typed, lastVisit)
    }
}

/// A tab of the window, as the dropdown matches it.
public struct OpenTab: Equatable, Sendable {
    public var url: String
    public var title: String

    public init(url: String, title: String) { (self.url, self.title) = (url, title) }
}

/// One dropdown row; `tab`: the index of the open tab that shows it ("Switch to tab"), nil when none does.
public struct Suggestion: Equatable, Sendable {
    public var url: String
    public var title: String
    public var tab: Int?

    public init(url: String, title: String, tab: Int?) { (self.url, self.title, self.tab) = (url, title, tab) }
}

/// What the address bar matches: every typed word appears in the url or the title, case- and
/// diacritic-insensitive (đ reads as d); a host that starts with the typed text ranks first.
public enum HistoryMatch {
    /// `text` lower case, without diacritics: "Tin Tức Đường" is "tin tuc duong".
    public static func fold(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
            .replacingOccurrences(of: "đ", with: "d")
    }

    /// The typed words, folded; a word typed with a scheme or `www.` is read without it ("https://exa" is
    /// "exa"); none for blank text.
    public static func words(_ typed: String) -> [String] {
        fold(typed).split(whereSeparator: { $0.isWhitespace }).map { bare(String($0)) }.filter { !$0.isEmpty }
    }

    /// The folded text the words are looked for in: the title and the url (percent escapes read).
    static func haystack(url: String, title: String) -> String {
        fold(title + "\n" + (url.removingPercentEncoding ?? url))
    }

    public static func matches(_ words: [String], url: String, title: String) -> Bool {
        let text = haystack(url: url, title: title)
        return !words.isEmpty && words.allSatisfy(text.contains)
    }

    /// The url without its scheme and a leading `www.`, folded: what a host prefix is read against.
    static func bare(_ url: String) -> String {
        var text = fold(url)
        for scheme in ["https://", "http://"] where text.hasPrefix(scheme) { text.removeFirst(scheme.count) }
        if text.hasPrefix("www.") { text.removeFirst(4) }
        return text
    }

    /// The typed text a host prefix is read with: one word, bare; nil when it cannot be one.
    static func prefixKey(_ typed: String) -> String? {
        let words = words(typed)
        guard words.count == 1 else { return nil }
        return words.first
    }

    public static func isHostPrefix(_ typed: String, url: String) -> Bool {
        prefixKey(typed).map { bare(url).hasPrefix($0) } ?? false
    }

    /// The dropdown's rows: the store's (best first) then the open tabs it lacks, each matching `typed`; a row
    /// on a host prefix first; one row per url; at most `limit`.
    public static func suggestions(history: [HistoryEntry], tabs: [OpenTab], typed: String,
                                   limit: Int = HistoryStore.shown) -> [Suggestion] {
        let words = words(typed)
        guard !words.isEmpty else { return [] }
        let tabOf = { (url: String) in tabs.firstIndex { $0.url == url } }
        var rows = history.filter { matches(words, url: $0.url, title: $0.title) }
            .map { Suggestion(url: $0.url, title: $0.title, tab: tabOf($0.url)) }
        for (index, tab) in tabs.enumerated() where !tab.url.isEmpty && matches(words, url: tab.url, title: tab.title) {
            if !rows.contains(where: { $0.url == tab.url }) {
                rows.append(Suggestion(url: tab.url, title: tab.title, tab: index))
            }
        }
        let first = rows.filter { isHostPrefix(typed, url: $0.url) }
        return Array((first + rows.filter { !isHostPrefix(typed, url: $0.url) }).prefix(limit))
    }
}
