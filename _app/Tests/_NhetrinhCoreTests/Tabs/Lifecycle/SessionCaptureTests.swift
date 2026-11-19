import Foundation
import Testing
@testable import NhetrinhCore

// P1-BUILD-1: what the app saves from its tabs, where it saves it, and a selection past the tabs.

private func url(_ text: String) -> URL? { URL(string: "https://example.com/" + text) }

struct CaptureCase: CustomTestStringConvertible {
    let testDescription: String
    let urls: [URL?]
    let selected: Int
    let savedURLs: [URL?]
    let savedSelected: Int
}

let captureCases = [
    CaptureCase(testDescription: "every tab has an address", urls: [url("a"), url("b"), url("c")], selected: 1,
                savedURLs: [url("a"), url("b"), url("c")], savedSelected: 1),
    CaptureCase(testDescription: "an empty new tab before the selected one", urls: [url("a"), nil, url("b")],
                selected: 2, savedURLs: [url("a"), url("b")], savedSelected: 1),
    CaptureCase(testDescription: "the selected tab is an empty new tab", urls: [url("a"), url("b"), nil],
                selected: 2, savedURLs: [url("a"), url("b")], savedSelected: 1),
    CaptureCase(testDescription: "only empty tabs", urls: [nil, nil], selected: 1, savedURLs: [], savedSelected: 0),
]

/// A new tab with no address is not saved, and the selection follows the tab it was on.
@Test(arguments: captureCases)
func captureSkipsTabsWithoutAddress(run: CaptureCase) {
    let tabs = run.urls.enumerated().map { (url: $0.element, title: "Tab \($0.offset)") }
    let session = Session.capture(tabs, selected: run.selected, sidebarWidth: 250, collapsed: true)
    #expect(session.tabs.map(\.url) == run.savedURLs.compactMap { $0 })
    #expect(session.selectedIndex == run.savedSelected && session.sidebarWidth == 250 && session.collapsed)
}

/// A file that points past its tabs (edited by hand) selects the nearest tab, never crashes.
@Test(arguments: [(saved: 7, loaded: 2), (saved: -3, loaded: 0), (saved: 1, loaded: 1)])
func selectionPastTheTabsIsClamped(saved: Int, loaded: Int) throws {
    let folder = FileManager.default.temporaryDirectory.appendingPathComponent("nhetrinh-clamp-\(UUID())")
    defer { try? FileManager.default.removeItem(at: folder) }
    let tabs = ["a", "b", "c"].compactMap { url($0).map { SessionTab(url: $0, title: "") } }
    try SessionStore.save(Session(tabs: tabs, selectedIndex: saved, sidebarWidth: 220, collapsed: false), in: folder)
    let home = try #require(url("home"))
    #expect(SessionStore.load(from: folder, home: home).selectedIndex == loaded)
}

/// A bad file is reported (the app logs it); a good one is not.
@Test(arguments: [(bytes: "not JSON", reported: true), (bytes: "", reported: false)])
func badFileIsReported(bytes: String, reported: Bool) throws {
    let folder = FileManager.default.temporaryDirectory.appendingPathComponent("nhetrinh-report-\(UUID())")
    defer { try? FileManager.default.removeItem(at: folder) }
    let home = try #require(url("home"))
    if bytes.isEmpty {
        try SessionStore.save(.home(home), in: folder)
    } else {
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        try Data(bytes.utf8).write(to: folder.appendingPathComponent(SessionStore.fileName))
    }
    var heard: [String] = []
    _ = SessionStore.load(from: folder, home: home) { heard.append($0) }
    #expect(heard.isEmpty == !reported)
}
