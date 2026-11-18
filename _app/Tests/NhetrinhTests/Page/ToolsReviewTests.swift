import AppKit
import NhetrinhCore
import Testing
@testable import Nhetrinh

/// P4P6-REVIEW (REVIEW_P4_P6.md, F5), red on p6/memory 96130c6: the find bar's answer belongs to the
/// page it searched. `select` leaves the bar and its answer as they were, so another tab shows
/// "Not found" (and the probe reads "not found") for a search it never ran. No page is loaded.
@MainActor
struct FindReviewTests {
    @Test(arguments: [false, true])
    func anAnswerIsNotCarriedToAnotherTab(found: Bool) {
        _ = NSApplication.shared
        let browser = BrowserWindowController()
        browser.tabs = [Tab(url: nil, title: "a"), Tab(url: nil, title: "b")]
        browser.select(0)
        browser.showFind(nil)
        browser.findBar.show(found: found)
        #expect(browser.findBar.result == (found ? "found" : "not found"), "the control: the answer is shown")
        browser.select(1)
        #expect(browser.findBar.result == "", "tab b never searched, yet the bar says \"\(browser.findBar.result)\"")
        browser.tabs.forEach { $0.unload() }
    }
}

/// P4P6-FIX-1, red first: F8 (a zoom reaches every loaded tab of the host), F9 (⌘= zooms in too, as on
/// a keyboard where + needs Shift), F6 (Clear All forgets the zoom per host). No page is loaded.
@MainActor
struct ZoomReviewTests {
    /// Three loaded tabs, a.test twice (one written upper case) and b.test; tab 1 selected.
    private func browser() -> BrowserWindowController {
        _ = NSApplication.shared
        let browser = BrowserWindowController()
        browser.tabs = (0..<3).map { _ in Tab(url: nil) }
        browser.tabs.forEach { browser.load($0) }
        for (tab, link) in zip(browser.tabs, ["https://a.test/1", "https://A.TEST:8080/2", "https://b.test/"]) {
            tab.url = URL(string: link)
        }
        browser.select(0)
        return browser
    }

    @Test func zoomReachesEveryLoadedTabOfTheHost() throws {
        let browser = browser()
        browser.zoomIn(nil)
        #expect(browser.tabs.map { Double($0.webView?.pageZoom ?? 0) } == [1.1, 1.1, 1.0])
        #expect(browser.prefs.zoom == ["a.test": 1.1])
        browser.tabs.forEach { $0.unload() }
    }

    @Test func zoomInHasBothKeys() throws {
        let browser = browser()
        let view = try #require(AppMenu.build(browser: browser).item(withTitle: "View")?.submenu)
        let zoomIn = view.items.filter { $0.action == #selector(BrowserWindowController.zoomIn(_:)) }
        #expect(Set(zoomIn.map(\.keyEquivalent)) == ["+", "="])
        #expect(zoomIn.allSatisfy { $0.keyEquivalentModifierMask == .command && $0.target === browser })
        let hiddenWork = zoomIn.filter(\.isHidden).allSatisfy { $0.allowsKeyEquivalentWhenHidden }
        #expect(hiddenWork, "a hidden item must still answer its key")
        #expect(browser.probeState(menu: AppMenu.build(browser: browser)).shortcuts["View > Zoom In"] == "⌘+")
        browser.tabs.forEach { $0.unload() }
    }

    /// Clear All forgets the zoom per host; Clear Last Hour keeps it (it has no date to go by).
    @Test(arguments: [(ClearRange.all, [String: Double]()), (.lastHour, ["a.test": 1.5])])
    func clearAllForgetsTheZoom(range: ClearRange, kept: [String: Double]) {
        _ = NSApplication.shared
        let hub = SettingsHub(store: .nonPersistent())
        var prefs = Prefs()
        prefs.zoom = ["a.test": 1.5]
        hub.onChange = { change in change(&prefs) }
        hub.clear(range)
        #expect(prefs.zoom == kept)
    }
}
