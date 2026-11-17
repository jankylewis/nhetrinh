import AppKit
import NhetrinhCore
import Testing
import WebKit
@testable import Nhetrinh

// P5-FIX-1 (rulings on nhetrinh_wt/REVIEW_P5.md), red first: the partial name and the quarantine on a real
// download (F1, F5, F6), the sheet past 5 downloads without a click (F2), every running row (F2), stalled (F9).

/// The most a wait on a fresh `.nonPersistent()` web view looks: it starts WebKit's processes, slow on a
/// loaded machine. Not a timing: each wait ends at its event; this only ends a test that would hang.
private let coldWebKit = 120.0

@MainActor
struct DownloadGuardTests {
    /// While it runs the file is `race.txt.download`; finished, it has its name and the quarantine of a web download.
    @Test func aDownloadIsPartialUntilDoneThenQuarantined() async throws {
        let folder = try downloadFolder()
        let server = try LoopbackServer()
        defer {
            server.stop()
            try? FileManager.default.removeItem(at: folder)
        }
        try #require(await server.waitReady(), "the loopback server")
        let downloads = Downloads(folder: folder)
        let pages = DownloadingPages(downloads)
        let slow = downloadPage(pages)
        load("slow", from: server, in: slow)
        let running = try await partialFile(of: downloads, in: folder)
        #expect(running == ["race.txt.download"], "while it runs the folder holds \(running)")
        #expect(downloads.cancel(row: 0))
        let fast = downloadPage(pages)
        load("fast", from: server, in: fast)
        try #require(await eventually(coldWebKit) { downloads.list.shownItems.first?.state == .finished }, "the end")
        let name = try #require(downloads.list.shownItems.first?.name)
        let file = folder.appendingPathComponent(name)
        // WebKit's sandboxed network process already marks its files "LSQuarantineTypeSandboxed" (seen in
        // P5-FIX-1 with the app's mark taken out); the app's is a web download, as Safari's.
        let quarantine = try file.resourceValues(forKeys: [.quarantinePropertiesKey]).quarantineProperties
        #expect(quarantine?["LSQuarantineType"] as? String == "LSQuarantineTypeWebDownload",
                "\(String(describing: quarantine))")
        #expect(quarantine?["LSQuarantineAgentName"] as? String == "nhetrinh")
        let left = try FileManager.default.contentsOfDirectory(atPath: folder.path)
        #expect(!left.contains { $0.hasSuffix(DownloadNamer.partialExtension) }, "a partial file is left: \(left)")
    }

    /// The folder while the slow download runs, read once WebKit holds the file. No clock: the row's rename to
    /// race.txt is the event that `canWrite`'s own race.txt.download is gone (`_Downloads.swift`), and only
    /// then is the folder read, once per look (NT-GAT in hubs: two reads raced that probe file).
    private func partialFile(of downloads: Downloads, in folder: URL) async throws -> [String] {
        let named = await eventually(coldWebKit) { downloads.list.shownItems.first?.name == "race.txt" }
        try #require(named, "the download is named: \(downloads.list.shownItems.map(\.name))")
        var running: [String] = []
        _ = await eventually(coldWebKit) {
            running = (try? FileManager.default.contentsOfDirectory(atPath: folder.path)) ?? []
            return !running.isEmpty
        }
        return running
    }

    /// 5 downloads without a click go; the 6th asks in a sheet; the 7th waits for the same answer.
    @Test(arguments: [("Allow", true), ("Don't Allow", false)])
    func theSixthUnclickedDownloadAsks(button: String, allowed: Bool) async {
        _ = NSApplication.shared
        let browser = BrowserWindowController()
        defer { browser.closeAfterTest() }
        let webView = WKWebView(frame: .zero)
        var answers: [Bool] = []
        for _ in 0..<7 { browser.admitDownload(from: webView) { answers.append($0) } }
        #expect(answers == Array(repeating: true, count: 5) && browser.shownSheet != nil)
        #expect(browser.probeState(menu: nil).sheetButtons.sorted() == ["Allow", "Don't Allow"])
        #expect(browser.probeAnswer(.sheetButton(button), menu: nil) == .done)
        _ = await eventually { answers.count == 7 }
        #expect(answers.suffix(2) == [allowed, allowed])
        browser.admitDownload(from: webView) { answers.append($0) }
        #expect(answers.last == allowed, "the answer holds for the page")
    }

    /// Every running download has a row in the footer, which scrolls past 3.
    @Test(arguments: [2, 7])
    func everyRunningDownloadHasAFooterRow(count: Int) {
        let downloads = Downloads(folder: nil)
        for index in 0..<count { downloads.list.add("file \(index)") }
        let bar = DownloadsBar()
        bar.show(downloads.list.shownItems)
        #expect(bar.shownRowCount == count)
    }

    /// No new bytes for 60 s: the row reads "stalled", and the footer is told.
    @Test func aQuietDownloadReadsStalled() {
        let downloads = Downloads(folder: nil)
        let id = downloads.list.add("a.zip", at: Date() - 61)
        var told = 0
        downloads.onChange = { told += 1 }
        downloads.checkStalls()
        #expect(downloads.list.item(id)?.stateText == "stalled" && told == 1)
    }
}
