import AppKit
import NhetrinhCore
import Testing
@testable import Nhetrinh

/// P7 tab folders through the user's paths: a row's menu, the name sheet, a drop, ⌘1 to ⌘9, a quit and
/// a launch (the session as it is saved and restored). No page loads: every tab is `about:blank?<n>`.
@MainActor
struct FoldersTests {
    /// t1 | work (t2, t3) | t4, the folder open or collapsed; tab `selected` (flat) selected.
    private func browser(collapsed: Bool = false, selected: Int = 0) -> BrowserWindowController {
        _ = NSApplication.shared
        let browser = BrowserWindowController()
        let tabs = (1...4).map { Tab(url: URL(string: "about:blank?\($0)"), title: "t\($0)") }
        let work = TreeFolder(name: "work", collapsed: collapsed, tabs: [tabs[1], tabs[2]])
        browser.tree = Tree(items: [.tab(tabs[0]), .folder(work), .tab(tabs[3])])
        browser.selected = selected
        browser.refreshChrome()
        return browser
    }

    private func state(_ browser: BrowserWindowController) -> ProbeState { browser.probeState(menu: nil) }

    /// The probe presses a sheet's button on the next turn of the main queue: wait for it (5 s at most).
    private func pressed(_ browser: BrowserWindowController) async {
        for _ in 0..<50 where browser.window?.attachedSheet != nil { try? await Task.sleep(nanoseconds: 100_000_000) }
    }

    @Test(arguments: [(false, ["t1", "work", "t2", "t3", "t4"]), (true, ["t1", "work", "t4"])])
    func theOutlineShowsFolders(collapsed: Bool, rows: [String]) {
        let shown = state(browser(collapsed: collapsed))
        #expect(shown.rows == rows && shown.folders == ["work"] && shown.folderTabs == [["t2", "t3"]])
        #expect(shown.collapsedFolders == [collapsed] && shown.loaded.count == rows.count)
    }

    /// New Folder… on a row asks a name in a sheet; Create puts the folder after that row's root item.
    @Test(arguments: [("Create", ["work", "news"]), ("Cancel", ["work"])])
    func newFolderAsksItsName(button: String, folders: [String]) async {
        let browser = browser()
        #expect(browser.probeAnswer(.rowMenu(row: 4, item: SidebarView.newFolder), menu: nil) == .done)
        #expect(browser.probeAnswer(.sheetField(index: 0, text: "  news "), menu: nil) == .done)
        #expect(browser.probeAnswer(.sheetButton(button), menu: nil) == .done)
        await pressed(browser)
        #expect(state(browser).folders == folders)
        if button == "Create" { #expect(state(browser).rows.last == "news") }
    }

    /// A folder's row menu: Rename Folder… (a sheet), Collapse Folder, Delete Folder (its tabs stay).
    @Test(arguments: ["Rename Folder…", "Collapse Folder", "Delete Folder"])
    func aFolderRowsMenu(item: String) async {
        let browser = browser()
        #expect(browser.probeAnswer(.rowMenu(row: 1, item: item), menu: nil) == .done)
        if item == "Rename Folder…" {
            _ = browser.probeAnswer(.sheetField(index: 0, text: "home"), menu: nil)
            _ = browser.probeAnswer(.sheetButton("Rename"), menu: nil)
            await pressed(browser)
        }
        let shown = state(browser)
        switch item {
        case "Rename Folder…": #expect(shown.folders == ["home"] && shown.folderTabs == [["t2", "t3"]])
        case "Collapse Folder": #expect(shown.rows == ["t1", "work", "t4"] && shown.collapsedFolders == [true])
        default: #expect(shown.rows == ["t1", "t2", "t3", "t4"] && shown.folders.isEmpty)
        }
    }

    /// Move to Folder, Move Out of Folder (a tab's row menu); the selection stays on its tab.
    @Test(arguments: [(0, "Move to Folder > work", [["t2", "t3", "t1"]]), (2, "Move Out of Folder", [["t3"]])])
    func aTabRowsMenuMovesIt(row: Int, item: String, folderTabs: [[String]]) {
        let browser = browser(selected: 0)
        #expect(browser.probeAnswer(.rowMenu(row: row, item: item), menu: nil) == .done)
        #expect(state(browser).folderTabs == folderTabs && browser.tabs[browser.selected].title == "t1")
    }

    /// A drag: onto the folder's row (its end), between its tabs; a folder onto a folder is refused.
    @Test func dropsIntoAFolder() throws {
        let browser = browser()
        let folder = try #require(browser.sidebar.node(atRow: 1))
        #expect(browser.sidebar.drop(TabPath(item: 2), onto: folder, at: NSOutlineViewDropOnItemIndex))
        #expect(state(browser).folderTabs == [["t2", "t3", "t4"]])
        let again = try #require(browser.sidebar.node(atRow: 1))
        #expect(browser.sidebar.drop(TabPath(item: 0), onto: again, at: 1))
        #expect(state(browser).folderTabs == [["t2", "t1", "t3", "t4"]])
        #expect(!browser.sidebar.drop(TabPath(item: 0), onto: try #require(browser.sidebar.node(atRow: 0)), at: 0))
    }

    /// ⌘1 to ⌘9 count the visible tabs: in a collapsed folder ⌘2 is t4.
    @Test(arguments: [(false, 2, "t2"), (true, 2, "t4"), (true, 9, "t4"), (false, 9, "t4")])
    func numberKeysCountVisibleTabs(collapsed: Bool, number: Int, title: String) {
        let browser = browser(collapsed: collapsed)
        let item = NSMenuItem()
        item.tag = number
        browser.selectTabByNumber(item)
        #expect(browser.tabs[browser.selected].title == title)
    }

    /// A collapsed folder that holds the selected tab is marked; no row is selected then.
    @Test(arguments: [(1, true), (0, false)])
    func aCollapsedFolderHoldingTheSelectionIsMarked(selected: Int, marked: Bool) throws {
        let browser = browser(collapsed: true, selected: selected)
        let row = try #require(browser.sidebar.table.view(atColumn: 0, row: 1, makeIfNecessary: true) as? FolderRowView)
        #expect(row.isMarked == marked && (browser.sidebar.selectedRow == -1) == marked)
    }

    /// What is saved is the tree as shown; restored, it shows the same rows and folders.
    @Test(arguments: [false, true])
    func foldersSurviveAQuit(collapsed: Bool) {
        let saved = browser(collapsed: collapsed, selected: 2).currentSession
        let restored = BrowserWindowController()
        restored.restore(saved)
        #expect(state(restored).rows == state(browser(collapsed: collapsed)).rows)
        #expect(restored.tabs[restored.selected].title == "t3" && state(restored).collapsedFolders == [collapsed])
    }
}
