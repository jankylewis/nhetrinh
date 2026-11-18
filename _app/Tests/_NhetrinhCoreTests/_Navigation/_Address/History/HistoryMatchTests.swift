import Foundation
import Testing
@testable import NhetrinhCore

/// P11-HISTORY (D30): every typed word appears in the url or the title, case- and diacritic-insensitive; the
/// store and the open tabs match the same way; a row already open in a tab says so.
struct HistoryMatchTests {
    @Test(arguments: [
        (typed: "news", match: true), (typed: "NEWS", match: true), (typed: "tin tuc", match: true),
        (typed: "tin tức", match: true), (typed: "TIN TỨC", match: true), (typed: "tuc news", match: true),
        (typed: "duong", match: true), (typed: "Đường", match: true), (typed: "news sport", match: false),
        (typed: "example.test/news", match: true), (typed: "café", match: true), (typed: "cafe", match: true),
        (typed: "", match: false), (typed: "   ", match: false), (typed: "tintuc", match: false),
    ])
    func everyWordInTheUrlOrTheTitle(typed: String, match: Bool) {
        let words = HistoryMatch.words(typed)
        #expect(HistoryMatch.matches(words, url: "https://example.test/news?q=caf%C3%A9",
                                     title: "Tin tức Đường phố") == match)
    }

    /// The store matches as `matches` does: words, case and diacritics, in the url or the title.
    @Test(arguments: ["tin tuc", "TIN TỨC", "duong", "news", "café", "tuc news"])
    func theStoreMatchesTheSameWay(typed: String) throws {
        let store = try HistoryRig.store()
        try HistoryRig.visit(store, "https://example.test/news?q=caf%C3%A9", title: "Tin tức Đường phố")
        try HistoryRig.visit(store, "https://other.test/", title: "Other")
        #expect(try HistoryRig.urls(store, typed) == ["https://example.test/news?q=caf%C3%A9"])
    }

    @Test(arguments: [
        (typed: "exa", prefix: true), (typed: "EXAMPLE.TEST", prefix: true), (typed: "www.ex", prefix: true),
        (typed: "https://ex", prefix: true), (typed: "http://www.example.test/a", prefix: true),
        (typed: "ample", prefix: false), (typed: "exa mple", prefix: false), (typed: "", prefix: false),
        (typed: "https", prefix: false), (typed: "https://", prefix: false),
    ])
    func theHostPrefix(typed: String, prefix: Bool) {
        #expect(HistoryMatch.isHostPrefix(typed, url: "https://www.example.test/a") == prefix)
    }

    @Test func anOpenTabSaysSwitchToTab() {
        let history = [entry("https://a.test/", "Alpha"), entry("https://b.test/", "Beta alpha")]
        let tabs = [OpenTab(url: "https://z.test/", title: "Zed"), OpenTab(url: "https://b.test/", title: "Beta")]
        let rows = HistoryMatch.suggestions(history: history, tabs: tabs, typed: "alpha")
        #expect(rows.map(\.url) == ["https://a.test/", "https://b.test/"])
        #expect(rows.map(\.tab) == [nil, 1])
    }

    /// History off: the dropdown still lists the open tabs that match; an open tab whose host starts with the
    /// typed text comes first; a page open twice is one row.
    @Test func openTabsAloneAndHostFirst() {
        let tabs = [OpenTab(url: "https://docs.test/x", title: "x docs"), OpenTab(url: "https://x.test/", title: "X"),
                    OpenTab(url: "https://x.test/", title: "X"), OpenTab(url: "https://y.test/", title: "Y")]
        let rows = HistoryMatch.suggestions(history: [], tabs: tabs, typed: "x")
        #expect(rows.map(\.url) == ["https://x.test/", "https://docs.test/x"])
        #expect(rows.map(\.tab) == [1, 0])
    }

    /// A new tab has no address: it is never a row, whatever its title.
    @Test func aTabWithoutAnAddressIsNoRow() {
        let tabs = [OpenTab(url: "", title: "New Tab"), OpenTab(url: "https://new.test/", title: "News")]
        #expect(HistoryMatch.suggestions(history: [], tabs: tabs, typed: "new").map(\.tab) == [1])
    }

    @Test func atMostEightRows() {
        let history = (0..<10).map { entry("https://h\($0).test/", "page") }
        let tabs = (0..<10).map { OpenTab(url: "https://t\($0).test/", title: "page") }
        #expect(HistoryMatch.suggestions(history: history, tabs: tabs, typed: "page").count == 8)
    }

    @Test func nothingTypedNoRows() {
        let rows = HistoryMatch.suggestions(history: [entry("https://a.test/", "A")],
                                            tabs: [OpenTab(url: "https://a.test/", title: "A")], typed: " ")
        #expect(rows.isEmpty)
    }

    private func entry(_ url: String, _ title: String) -> HistoryEntry {
        HistoryEntry(url: url, title: title, visits: 1, typed: 0, lastVisit: HistoryRig.now)
    }
}
