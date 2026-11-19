import AppKit
import NhetrinhCore
import Testing
@testable import Nhetrinh

/// Duplicate Tab (headmate, 2026-11-19), red first: a row's menu makes a copy right after the tab, in its group,
/// with its page, title and back / forward history; the copy is selected. The tree: _GroupsTests.swift.
@MainActor
struct DuplicateTabTests {
    /// Row 8 is t5, alone in Feedback (level 4); row 9 is t6, the last tab, at the top level.
    @Test(arguments: [(8, 4, ["t1", "MBing", "t2", "FE", "t3", "PRs", "t4", "Feedback", "t5", "t5", "t6"]),
                      (9, 5, ["t1", "MBing", "t2", "FE", "t3", "PRs", "t4", "Feedback", "t5", "t6", "t6"])]
          as [(Int, Int, [String])])
    func theCopyFollowsItsTabAndIsSelected(row: Int, flat: Int, rows: [String]) {
        let browser = groupBrowser()
        defer { browser.closeAfterTest() }
        browser.tabs[flat].savedState = "history"
        #expect(browser.probeAnswer(.rowMenu(row: row, item: SidebarView.duplicateTab), menu: nil) == .done)
        #expect(groupState(browser).rows == rows && browser.tabs.count == 7 && browser.selected == flat + 1)
        let (source, copy) = (browser.tabs[flat], browser.tabs[flat + 1])
        #expect(copy !== source && copy.url == source.url && copy.title == source.title)
        #expect(copy.savedState as? String == "history" || copy.isLoaded)
    }
}
