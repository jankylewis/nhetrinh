import AppKit
import Testing
@testable import Nhetrinh

/// NT-BUG-026, red first: an HTML file opened from Finder, or a `file:` link from another app, becomes a
/// tab and its page shows (WebKit reads a local file only with `loadFileURL`); a page handed off from
/// another device (Handoff) opens as a tab. Nothing goes to the network: the file is a temporary one.
@MainActor
struct LocalPageTests {
    private func browser() -> BrowserWindowController {
        _ = NSApplication.shared
        let browser = BrowserWindowController()
        browser.tabs = [Tab(url: nil, title: "t1")]
        browser.selected = 0
        browser.refreshChrome()
        return browser
    }

    @Test func aLocalFileOpensAsATabAndShows() async throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let page = folder.appendingPathComponent("page.html")
        try Data("<title>local page</title><p>hi</p>".utf8).write(to: page)
        let browser = browser()
        defer { browser.tabs.forEach { $0.unload() } }
        browser.openIncoming([page])
        try #require(browser.tabs.count == 2 && browser.selected == 1)
        let webView = try #require(browser.tabs[1].webView)
        for _ in 0..<50 where webView.title != "local page" { try await Task.sleep(nanoseconds: 100_000_000) }
        #expect(webView.title == "local page")
    }

    @Test func aPageHandedOffFromAnotherDeviceOpensAsATab() throws {
        let browser = browser()
        defer { browser.tabs.forEach { $0.unload() } }
        let activity = NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb)
        activity.webpageURL = URL(string: "http://127.0.0.1:9/handed-off")
        #expect(AppDelegate.continueBrowsing(activity, in: browser))
        #expect(browser.tabs.count == 2 && browser.tabs[1].url == activity.webpageURL)
        #expect(!AppDelegate.continueBrowsing(NSUserActivity(activityType: "x.other"), in: browser))
    }
}
