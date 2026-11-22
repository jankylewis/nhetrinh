import AppKit
import NhetrinhCore
import Testing
import WebKit
@testable import Nhetrinh

@MainActor
struct HistoryTitleTests {
    /// NT-BUG-029, red first: a page's title reaches the history even when WebKit reports it after `didFinish`
    /// (33 of the headmate's 88 rows had none: the dropdown showed "url — url"). A real web view, no network:
    /// the page is a string with a loopback base address.
    @Test func aLoadedPagesTitleReachesTheHistory() async throws {
        let browser = try AddressBarTests().browser()
        defer { browser.tabs.forEach { $0.unload() } }
        browser.select(0)
        let webView = try #require(browser.tabs[0].webView)
        let url = "http://127.0.0.1:9/titled"
        for round in 1...5 {
            let page = "<title>Titled page \(round)</title><p>hi</p>"
            webView.loadHTMLString(page, baseURL: URL(string: url + "\(round)"))
            let store = try #require(browser.history.store)
            for _ in 0..<50 where (try? store.entry(url: url + "\(round)"))??.title != "Titled page \(round)" {
                try await Task.sleep(nanoseconds: 100_000_000)
            }
            let title = try store.entry(url: url + "\(round)")?.title
            #expect(title == "Titled page \(round)", "round \(round): kept title \"\(title ?? "no row")\"")
        }
    }
}
