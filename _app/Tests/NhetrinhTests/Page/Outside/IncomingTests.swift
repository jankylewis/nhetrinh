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

    /// NT-BUG-031 (found_by: headmate): a PDF file from Finder (Open With) opens as a tab and WebKit shows it there;
    /// it is not saved as a download. The Info.plist claim itself is checked by `browser_claims` in `_build.sh`.
    @Test func aPDFFileOpensAsATabAndShows() async throws {
        _ = NSApplication.shared
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let file = folder.appendingPathComponent("doc.pdf")
        let page = NSTextField(labelWithString: "pdf page")
        page.frame = NSRect(x: 0, y: 0, width: 200, height: 40)
        try page.dataWithPDF(inside: page.bounds).write(to: file)
        let browser = BrowserWindowController()
        defer { browser.closeAfterTest() }
        browser.tabs = [Tab(url: nil, title: "t1")]
        browser.select(0)
        browser.openIncoming([file])
        let webView = try #require(browser.tabs.last?.webView)
        for _ in 0..<50 where webView.isLoading || webView.url != file {
            try await Task.sleep(nanoseconds: 100_000_000)
        }
        let type = try await webView.evaluateJavaScript("document.contentType") as? String
        #expect(browser.tabs.count == 2 && webView.url == file && type == "application/pdf", "type \(type ?? "-")")
    }
}
