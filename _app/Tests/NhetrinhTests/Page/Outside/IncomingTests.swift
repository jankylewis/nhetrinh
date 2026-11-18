import AppKit
import Testing
@testable import Nhetrinh

// P5-REVIEW (nhetrinh_wt/REVIEW_P5.md): red on origin/p5/downloads e7dccf9. No fix here.

/// Links from another app, several at once (a mail with 5 links, `open url1 url2 …`): each becomes a tab
/// and is selected in turn, and `select` loads it, so every one starts a page process at once. A tab
/// that was never shown costs no process (R7); only the last link, the one shown, should load.
/// The links are to a closed port of 127.0.0.1: nothing goes to the network.
@MainActor
struct IncomingTests {
    @Test(arguments: [3, 10])
    func linksFromAnotherAppLoadOnlyTheShownTab(count: Int) {
        _ = NSApplication.shared
        let browser = BrowserWindowController()
        browser.tabs = [Tab(url: nil, title: "t1")]
        browser.selected = 0
        browser.refreshChrome()
        let links = (1...count).compactMap { URL(string: "http://127.0.0.1:9/link\($0)") }
        browser.openIncoming(links)
        let loaded = browser.tabs.dropFirst().filter(\.isLoaded).count
        #expect(browser.tabs.count == count + 1 && loaded == 1, "\(count) links: \(loaded) tabs loaded")
        browser.tabs.forEach { $0.unload() }
    }
}
