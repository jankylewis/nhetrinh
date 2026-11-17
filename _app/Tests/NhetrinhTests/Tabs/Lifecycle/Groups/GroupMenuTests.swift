import AppKit
import NhetrinhCore
import Testing
@testable import Nhetrinh

/// P8-GROUPS-1, red first: the group and tab row menus, the refusal sheet, a drop, a double click. The tree
/// and its rows: _GroupsTests.swift.
@MainActor
struct GroupMenuTests {
    /// Press `item` on `row`'s menu; a name sheet gets `name` and its button `button`.
    private func press(_ browser: BrowserWindowController, row: Int, _ item: String, name: String? = nil,
                       button: String = "Create") async {
        #expect(browser.probeAnswer(.rowMenu(row: row, item: item), menu: nil) == .done)
        guard let name else { return }
        #expect(browser.probeAnswer(.sheetField(index: 0, text: name), menu: nil) == .done)
        #expect(browser.probeAnswer(.sheetButton(button), menu: nil) == .done)
        await sheetGone(browser)
    }

    /// The three ways to make a group, each asking a name.
    @Test(arguments: [(0, SidebarView.newGroup, "G"), (5, SidebarView.newGroupInside, "MBing > FE > PRs > G"),
                      (6, SidebarView.newGroupFromTab, "MBing > FE > PRs > G")] as [(Int, String, String)])
    func makeAGroup(row: Int, item: String, made: String) async {
        let browser = groupBrowser()
        await press(browser, row: row, item, name: "G")
        let paths: [String] = headmatePaths + [made]
        #expect(groupState(browser).groupPaths.sorted() == paths.sorted())
        #expect(groupState(browser).tabTitles == ["t1", "t2", "t3", "t4", "t5", "t6"])
    }

    /// New Group Inside… on Feedback (level 4): no name is asked; the sheet says why; nothing changes.
    @Test func aFifthLevelIsRefusedWithItsReason() async {
        let browser = groupBrowser()
        await press(browser, row: 7, SidebarView.newGroupInside)
        let state = groupState(browser)
        #expect(state.sheet.contains(TreeFailure.tooDeep.reason) && state.groupRefusal == TreeFailure.tooDeep.reason)
        #expect(browser.probeAnswer(.sheetButton("OK"), menu: nil) == .done)
        await sheetGone(browser)
        #expect(groupState(browser).groupPaths == headmatePaths)
    }

    /// Rename Group… (a sheet), and a double click on the group's name.
    @Test func renameByMenuAndByDoubleClick() async {
        let browser = groupBrowser()
        await press(browser, row: 5, "Rename Group…", name: "Pull requests", button: "Rename")
        #expect(groupState(browser).groupPaths[2] == "MBing > FE > Pull requests")
        browser.sidebar.doubleClick(row: 3)
        #expect(groupState(browser).sheet.contains("Rename Group"))
        #expect(browser.probeAnswer(.sheetButton("Cancel"), menu: nil) == .done)
        await sheetGone(browser)
    }

    /// Move Group to > Top Level, and back to MBing > FE; a group never into itself or too deep (item off).
    @Test func moveAGroupOutAndBack() async {
        let browser = groupBrowser()
        await press(browser, row: 5, "Move Group to > Top Level")
        #expect(groupState(browser).groupPaths == ["MBing", "MBing > FE", "PRs", "PRs > Feedback"])
        let row = groupState(browser).rows.firstIndex(of: "PRs") ?? -1
        await press(browser, row: row, "Move Group to > MBing > FE")
        #expect(groupState(browser).groupPaths == headmatePaths)
        for refused in ["MBing > FE > PRs", "MBing > FE > PRs > Feedback"] {
            #expect(browser.probeAnswer(.rowMenu(row: 3, item: "Move Group to > \(refused)"), menu: nil) != .done)
        }
    }

    /// Ungroup FE: its tab and its group move up into MBing, in its place; no tab closes.
    @Test func ungroupMovesItsItemsUp() async {
        let browser = groupBrowser()
        await press(browser, row: 3, "Ungroup")
        #expect(groupState(browser).groupPaths == ["MBing", "MBing > PRs", "MBing > PRs > Feedback"])
        #expect(groupState(browser).rows == ["t1", "MBing", "t2", "t3", "PRs", "t4", "Feedback", "t5", "t6"])
    }

    /// Move Tab to Group (a path) and Move Out of Group (one level up, after its group).
    @Test(arguments: [(0, "Move Tab to Group > MBing > FE > PRs > Feedback", ["t2", "t3", "t4", "t5", "t1", "t6"]),
                      (8, "Move Out of Group", ["t1", "t2", "t3", "t4", "t5", "t6"])])
    func moveATab(row: Int, item: String, order: [String]) async {
        let browser = groupBrowser()
        await press(browser, row: row, item)
        #expect(groupState(browser).tabTitles == order)
        #expect(groupState(browser).groupCounts == (row == 0 ? [5, 4, 3, 2] : [4, 3, 2, 0]))
    }

    /// A drag: a group with all inside to the top level; into its own group or a tab's row: refused.
    @Test func dropAGroup() throws {
        let browser = groupBrowser()
        #expect(browser.sidebar.drop(TabPath([1, 1, 1]), onto: nil, at: 0))
        #expect(groupState(browser).groupPaths == ["PRs", "PRs > Feedback", "MBing", "MBing > FE"])
        let feedback = try #require(browser.sidebar.node(at: TabPath([0, 1])))
        #expect(!browser.sidebar.drop(TabPath([0]), onto: feedback, at: 0))
        #expect(!browser.sidebar.drop(TabPath([0]), onto: try #require(browser.sidebar.node(at: TabPath([1]))), at: 0))
    }
}
