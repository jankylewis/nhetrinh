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

    /// NT-BUG-027, red first: a local page in a subfolder uses its parent's style and links there, as the
    /// storybook pages do (`../style.css`, `../other.html`). Read access to the file's own folder only broke both.
    @Test func aLocalPageReadsAndOpensItsParentsFiles() async throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let sub = folder.appendingPathComponent("sub")
        try FileManager.default.createDirectory(at: sub, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        try Data("body { margin-left: 37px }".utf8).write(to: folder.appendingPathComponent("style.css"))
        try Data("<title>parent page</title>".utf8).write(to: folder.appendingPathComponent("other.html"))
        let page = sub.appendingPathComponent("page.html")
        try Data("<title>child</title><link rel=stylesheet href=../style.css><a href=../other.html>go</a>".utf8)
            .write(to: page)
        let browser = browser()
        defer { browser.tabs.forEach { $0.unload() } }
        browser.openIncoming([page])
        let webView = try #require(browser.tabs.last?.webView)
        for _ in 0..<50 where webView.title != "child" || webView.isLoading {
            try await Task.sleep(nanoseconds: 100_000_000)
        }
        let margin = try await webView.evaluateJavaScript("getComputedStyle(document.body).marginLeft") as? String
        #expect(margin == "37px")
        _ = try await webView.evaluateJavaScript("document.querySelector('a').click(); 0")
        for _ in 0..<50 where webView.title != "parent page" { try await Task.sleep(nanoseconds: 100_000_000) }
        #expect(webView.title == "parent page")
        let read = "fetch('style.css').then(r => r.text()).then(() => 'read', () => 'blocked')"
        let answer = try await webView.callAsyncJavaScript("return await \(read)", contentWorld: .page) as? String
        #expect(answer == "blocked")  // a page's script still cannot read another file
    }

    /// A local page that rests comes back on the page it showed, with its back list (as a web page does).
    @Test func aRestingLocalPageComesBackWithItsHistory() async throws {
        let (folder, page) = try twoPages()
        defer { try? FileManager.default.removeItem(at: folder) }
        let browser = browser()
        defer { browser.tabs.forEach { $0.unload() } }
        browser.openIncoming([page])
        let first = try #require(browser.tabs.last?.webView)
        try await wait { first.title == "a" && !first.isLoading }
        _ = try await first.evaluateJavaScript("document.querySelector('a').click(); 0")
        try await wait { first.title == "b" && !first.isLoading }
        browser.select(0)
        browser.tabs[1].unload()
        browser.select(1)
        let again = try #require(browser.tabs[1].webView)
        try await wait { again.title == "b" && again.canGoBack }
        #expect(again.title == "b" && again.canGoBack, "title \(again.title ?? "-"), back \(again.canGoBack)")
        try await wait { !again.isLoading }
        let shown = "document.body.innerText + ' ' + getComputedStyle(document.body).marginLeft"
        #expect(try await again.evaluateJavaScript(shown) as? String == "B 37px")  // read from disk, not kept
        again.goBack()
        try await wait { again.title == "a" && !again.isLoading }
        #expect(try await again.evaluateJavaScript("document.body.innerText") as? String == "b")
    }

    /// `a.html` links to `sub/b.html`, which uses `../s.css` (a left margin of 37 px).
    private func twoPages() throws -> (URL, URL) {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let sub = folder.appendingPathComponent("sub")
        try FileManager.default.createDirectory(at: sub, withIntermediateDirectories: true)
        try Data("<title>b</title><link rel=stylesheet href=../s.css>B".utf8)
            .write(to: sub.appendingPathComponent("b.html"))
        try Data("body { margin-left: 37px }".utf8).write(to: folder.appendingPathComponent("s.css"))
        let page = folder.appendingPathComponent("a.html")
        try Data("<title>a</title><a href=sub/b.html>b</a>".utf8).write(to: page)
        return (folder, page)
    }

    private func wait(_ done: () -> Bool) async throws {
        for _ in 0..<50 where !done() { try await Task.sleep(nanoseconds: 100_000_000) }
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
