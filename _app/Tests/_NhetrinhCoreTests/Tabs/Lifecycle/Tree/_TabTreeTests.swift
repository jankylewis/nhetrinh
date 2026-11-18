import Foundation
import Testing
@testable import NhetrinhCore

// P7 tests (hubs/product/plan/M3_V1_RELEASE.md), written red first on stubs (P7-PREP-1, DECISIONS.md D24).
// Folders: add, rename, collapse, delete (its tabs stay), what the sidebar shows. Moves: TabTreeMoveTests.

/// A tab named `name`, at https://<name>.example/.
func treeTab(_ name: String) -> SessionTab {
    SessionTab(url: URL(string: "https://\(name).example/") ?? URL(fileURLWithPath: "/"), title: name)
}

func treeFolder(_ name: String, _ tabs: [String], collapsed: Bool = false) -> TabTree.Item {
    .folder(TabFolder(name: name, collapsed: collapsed, tabs: tabs.map(treeTab)))
}

func treeRoot(_ name: String) -> TabTree.Item { .tab(treeTab(name)) }

/// a | work (b, c) | d
func sampleTree(collapsed: Bool = false) -> TabTree {
    TabTree(items: [treeRoot("a"), treeFolder("work", ["b", "c"], collapsed: collapsed), treeRoot("d")])
}

/// A version 1 list becomes root tabs, in order.
@Test(arguments: [1, 3])
func flatTabsBecomeRootTabs(count: Int) {
    let tabs = ["a", "b", "c"].prefix(count).map(treeTab)
    let tree = TabTree(tabs: Array(tabs))
    #expect(tree.items == tabs.map { .tab($0) } && tree.allTabs == Array(tabs))
}

/// Every tab in order, folders opened; a collapsed folder hides its tabs from what the sidebar shows.
@Test(arguments: [(false, ["a", "b", "c", "d"]), (true, ["a", "d"])])
func collapsedFolderHidesItsTabs(collapsed: Bool, visible: [String]) {
    let tree = sampleTree(collapsed: collapsed)
    #expect(tree.allTabs.map(\.title) == ["a", "b", "c", "d"])
    #expect(tree.visibleTabs.map(\.title) == visible)
}

@Test(arguments: [(0, "work", 0), (1, "  work  ", 1), (2, "work", 2)])
func addFolderPutsAnEmptyOpenFolderAt(index: Int, name: String, at place: Int) throws {
    var tree = TabTree(items: [treeRoot("a"), treeRoot("b")])
    try tree.addFolder(named: name, at: index)
    var expected: [TabTree.Item] = [treeRoot("a"), treeRoot("b")]
    expected.insert(.folder(TabFolder(name: "work")), at: place)
    #expect(tree.items == expected)
}

@Test(arguments: [(3, "work", TabTree.Failure.noSuchPlace), (-1, "work", .noSuchPlace), (0, "   ", .emptyName)])
func addFolderRefuses(index: Int, name: String, failure: TabTree.Failure) {
    var tree = TabTree(items: [treeRoot("a"), treeRoot("b")])
    #expect(throws: failure) { try tree.addFolder(named: name, at: index) }
    #expect(tree.items == [treeRoot("a"), treeRoot("b")])
}

@Test(arguments: [("home", "home"), ("  tên có dấu 🎵 ", "tên có dấu 🎵")])
func renameKeepsTheTabs(name: String, kept: String) throws {
    var tree = sampleTree()
    try tree.rename(folder: 1, to: name)
    #expect(tree.items == [treeRoot("a"), treeFolder(kept, ["b", "c"]), treeRoot("d")])
}

@Test(arguments: [(1, " ", TabTree.Failure.emptyName), (0, "x", .notAFolder), (3, "x", .noSuchPlace)])
func renameRefuses(index: Int, name: String, failure: TabTree.Failure) {
    var tree = sampleTree()
    #expect(throws: failure) { try tree.rename(folder: index, to: name) }
    #expect(tree == sampleTree())
}

@Test(arguments: [true, false])
func collapseAndOpen(collapsed: Bool) throws {
    var tree = sampleTree(collapsed: !collapsed)
    try tree.setCollapsed(collapsed, folder: 1)
    #expect(tree == sampleTree(collapsed: collapsed))
}

@Test(arguments: [(0, TabTree.Failure.notAFolder), (5, .noSuchPlace)])
func collapseRefuses(index: Int, failure: TabTree.Failure) {
    var tree = sampleTree()
    #expect(throws: failure) { try tree.setCollapsed(true, folder: index) }
    #expect(tree == sampleTree())
}

/// Deleting a folder never closes a tab: they go to the root in its place, in order (open or collapsed).
@Test(arguments: [false, true])
func deleteFolderKeepsItsTabs(collapsed: Bool) throws {
    var tree = sampleTree(collapsed: collapsed)
    try tree.deleteFolder(at: 1)
    #expect(tree.items == ["a", "b", "c", "d"].map(treeRoot))
    #expect(tree.allTabs == sampleTree().allTabs)
}

@Test func deleteAnEmptyFolder() throws {
    var tree = TabTree(items: [treeRoot("a"), treeFolder("empty", []), treeRoot("d")])
    try tree.deleteFolder(at: 1)
    #expect(tree.items == [treeRoot("a"), treeRoot("d")])
}

@Test(arguments: [(0, TabTree.Failure.notAFolder), (3, .noSuchPlace), (-1, .noSuchPlace)])
func deleteFolderRefuses(index: Int, failure: TabTree.Failure) {
    var tree = sampleTree()
    #expect(throws: failure) { try tree.deleteFolder(at: index) }
    #expect(tree == sampleTree())
}
