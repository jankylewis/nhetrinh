import AppKit
import NhetrinhCore
import Testing
@testable import Nhetrinh

/// NT-FEAT-063 (headmate request), red first: one click anywhere on a group's row opens or closes it, as the
/// disclosure arrow does; a double click still renames and leaves the group as it was. Rows: _GroupsTests.swift.
@MainActor
struct GroupClickTests {
    /// The collapsed state of the four groups, outermost first.
    private func collapsed(_ browser: BrowserWindowController) -> [Bool] { groupState(browser).collapsedFolders }

    @Test func aClickOnAGroupsRowClosesItAndAnotherOpensIt() {
        let browser = groupBrowser()
        defer { browser.closeAfterTest() }
        browser.sidebar.click(row: 3)
        #expect(collapsed(browser) == [false, true, false, false])
        #expect(groupState(browser).rows == ["t1", "Work", "t2", "FE", "t6"])
        browser.sidebar.click(row: 3)
        #expect(collapsed(browser) == [false, false, false, false])
        #expect(groupState(browser).rows.count == 10 && browser.selected == 0)
        #expect(groupState(browser).sheet.isEmpty)
    }

    /// A double click is a click and then the double click: the rename sheet, and the group as it was.
    @Test func aDoubleClickRenamesAndKeepsTheGroupAsItWas() async {
        let browser = groupBrowser(collapsed: ["Feedback"])
        defer { browser.closeAfterTest() }
        browser.sidebar.click(row: 7)
        browser.sidebar.doubleClick(row: 7)
        #expect(collapsed(browser) == [false, false, false, true])
        #expect(groupState(browser).sheet.contains("Rename Group"))
        #expect(browser.probeAnswer(.sheetButton("Cancel"), menu: nil) == .done)
        await sheetGone(browser)
    }

    @Test func aClickOnATabsRowLeavesTheGroupsAlone() {
        let browser = groupBrowser()
        defer { browser.closeAfterTest() }
        browser.sidebar.click(row: 4)
        browser.sidebar.doubleClick(row: 4)
        #expect(collapsed(browser) == [false, false, false, false])
    }
}
