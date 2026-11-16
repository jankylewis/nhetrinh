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
