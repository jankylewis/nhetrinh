import AppKit
import NhetrinhCore
import Testing
@testable import Nhetrinh

/// P8-GROUPS-1 (headmate request), red first: nested groups through the user's paths. No page loads: every
/// tab is `about:blank?<n>`. The tree: t1 | MBing (t2 | FE (t3 | PRs (t4 | Feedback (t5)))) | t6; its rows,
/// all open: 0 t1, 1 MBing, 2 t2, 3 FE, 4 t3, 5 PRs, 6 t4, 7 Feedback, 8 t5, 9 t6. Menus: GroupMenuTests.
@MainActor
func groupBrowser(collapsed: Set<String> = [], selected: Int = 0) -> BrowserWindowController {
    _ = NSApplication.shared
    let browser = BrowserWindowController()
    let tabs = (1...6).map { Tab(url: URL(string: "about:blank?\($0)"), title: "t\($0)") }
    func box(_ name: String, _ items: Tree<Tab>.Item...) -> Tree<Tab>.Item {
        .folder(TreeFolder(name: name, collapsed: collapsed.contains(name), items: items))
    }
    let feedback = box("Feedback", .tab(tabs[4]))
    let mbing = box("MBing", .tab(tabs[1]), box("FE", .tab(tabs[2]), box("PRs", .tab(tabs[3]), feedback)))
    browser.tree = Tree(items: [.tab(tabs[0]), mbing, .tab(tabs[5])])
    browser.selected = selected
    browser.refreshChrome()
    return browser
}

let headmatePaths = ["MBing", "MBing > FE", "MBing > FE > PRs", "MBing > FE > PRs > Feedback"]

@MainActor
func groupState(_ browser: BrowserWindowController) -> ProbeState { browser.probeState(menu: nil) }

/// The probe presses a sheet's button on the next turn of the main queue: wait for it (5 s at most).
@MainActor
func sheetGone(_ browser: BrowserWindowController) async {
    for _ in 0..<50 where browser.shownSheet != nil { try? await Task.sleep(nanoseconds: 100_000_000) }
}

@MainActor
struct GroupsTests {
    @Test func theOutlineIndentsByLevelAndCountsTabs() throws {
        let browser = groupBrowser()
        let state = groupState(browser)
        #expect(state.rows == ["t1", "MBing", "t2", "FE", "t3", "PRs", "t4", "Feedback", "t5", "t6"])
        #expect(state.rowLevels == [0, 0, 1, 1, 2, 2, 3, 3, 4, 0])
        #expect(state.groupPaths == headmatePaths && state.groupCounts == [4, 3, 2, 1])
        #expect(state.tabTitles == ["t1", "t2", "t3", "t4", "t5", "t6"])
        let row = try #require(browser.sidebar.table.view(atColumn: 0, row: 1, makeIfNecessary: true) as? FolderRowView)
        #expect(row.shownCount == "4")
    }

    /// ⌘1 to ⌘9 skip a tab when any group above it is collapsed; the collapsed group holding it is marked.
    @Test(arguments: [(["FE"], 3, "t6"), (["Feedback"], 5, "t6"), (["MBing"], 2, "t6"), ([], 5, "t5")]
          as [(Set<String>, Int, String)])
    func numberKeysSkipCollapsedGroups(collapsed: Set<String>, number: Int, title: String) {
        let browser = groupBrowser(collapsed: collapsed)
        let item = NSMenuItem()
        item.tag = number
        browser.selectTabByNumber(item)
        #expect(browser.tabs[browser.selected].title == title)
    }

    @Test func aCollapsedAncestorOfTheSelectionIsMarked() throws {
        let browser = groupBrowser(collapsed: ["FE"], selected: 4)
        let row = try #require(browser.sidebar.table.view(atColumn: 0, row: 3, makeIfNecessary: true) as? FolderRowView)
        #expect(row.isMarked && browser.sidebar.selectedRow == -1 && groupState(browser).rows.count == 5)
    }

    /// Close Group…: a confirmation names the tab count; Close closes the group and its tabs; Reopen Closed
    /// Tab brings the group back where it was, its tab selected.
    @Test func closeGroupAndReopenIt() async {
        let browser = groupBrowser()
        defer { browser.closeAfterTest() }
        #expect(browser.probeAnswer(.rowMenu(row: 5, item: "Close Group…"), menu: nil) == .done)
        #expect(groupState(browser).sheet.contains("“PRs” and its 2 tabs?"))
        #expect(browser.probeAnswer(.sheetButton("Close"), menu: nil) == .done)
        await sheetGone(browser)
        #expect(groupState(browser).tabTitles == ["t1", "t2", "t3", "t6"])
        #expect(groupState(browser).groupPaths == ["MBing", "MBing > FE"] && browser.closedTabs.count == 1)
        browser.reopenClosedTab(nil)
        #expect(groupState(browser).groupPaths == headmatePaths && groupState(browser).tabTitles.count == 6)
        #expect(browser.tabs[browser.selected].title == "t4")
        browser.tabs.forEach { $0.unload() }
    }

    /// The tree survives a quit and a launch: every level, every collapsed state, the selected tab.
    @Test(arguments: [[], ["PRs"], ["FE", "Feedback"]] as [Set<String>])
    func nestedGroupsSurviveAQuit(collapsed: Set<String>) {
        let saved = groupBrowser(collapsed: collapsed, selected: 4).currentSession
        let restored = BrowserWindowController()
        restored.restore(saved)
        let before = groupState(groupBrowser(collapsed: collapsed, selected: 4))
        #expect(groupState(restored).rows == before.rows && groupState(restored).groupPaths == headmatePaths)
        #expect(groupState(restored).collapsedFolders == before.collapsedFolders)
        #expect(restored.tabs[restored.selected].title == "t5")
    }

    /// R-11: a page's new title updates its row in place; a change of the tree's shape reloads the outline.
    @Test func onlyAShapeChangeReloadsTheOutline() {
        let browser = groupBrowser()
        let reloads = browser.sidebar.reloads
        browser.tabs[5].title = "renamed"
        browser.refreshChrome()
        #expect(browser.sidebar.reloads == reloads && groupState(browser).rows.last == "renamed")
        browser.sidebarAction(.setCollapsed(TabPath([1, 1]), true))
        #expect(browser.sidebar.reloads == reloads + 1 && groupState(browser).rows.count == 5)
    }
}
