import AppKit
import Testing
@testable import Nhetrinh

/// NT-FEAT-064 (headmate, 2026-11-23: "like other browsers"), red first: the pointer resting on a tab's row shows
/// the tab's title and its full address as a tooltip; a tab with no address shows its title only.
@MainActor
struct TabTooltipTests {
    private func browser(_ urls: [String?]) -> BrowserWindowController {
        _ = NSApplication.shared
        let browser = BrowserWindowController()
        browser.tabs = urls.enumerated().map { Tab(url: $1.flatMap(URL.init(string:)), title: "t\($0 + 1)") }
        browser.selected = 0
        browser.refreshChrome()
        return browser
    }

    private func tip(_ browser: BrowserWindowController, row: Int) throws -> String? {
        try #require(browser.sidebar.table.view(atColumn: 0, row: row, makeIfNecessary: true) as? TabRowView).toolTip
    }

    @Test(arguments: [
        ("https://example.com/a/very/long/path?q=1#part", "t1\nhttps://example.com/a/very/long/path?q=1#part"),
        (nil, "t1"),
    ] as [(String?, String)])
    func aTabsRowShowsItsTitleAndFullAddress(url: String?, expected: String) throws {
        let browser = browser([url])
        defer { browser.closeAfterTest() }
        #expect(try tip(browser, row: 0) == expected)
    }

    /// A page that moves to a new address in the same tab: the row's tooltip follows, with no reload (R-11).
    @Test func theTooltipFollowsANewAddress() throws {
        let browser = browser(["https://example.com/one", "https://example.com/two"])
        defer { browser.closeAfterTest() }
        _ = try tip(browser, row: 1)
        let reloads = browser.sidebar.reloads
        browser.tabs[1].url = URL(string: "https://example.org/three")
        browser.refreshChrome()
        #expect(try tip(browser, row: 1) == "t2\nhttps://example.org/three")
        #expect(browser.sidebar.reloads == reloads)
    }
}
