import Foundation
import Testing
@testable import NhetrinhCore

// P7-BUILD-1: the tree as the app's flat tab list (TreeFlat.swift). The tree is a | work (b, c) | d.

@Test(arguments: [(0, TabPath(item: 0)), (1, TabPath(item: 1, tab: 0)), (2, TabPath(item: 1, tab: 1)),
                  (3, TabPath(item: 2))])
func flatIndexAndPathAgree(flat: Int, path: TabPath) {
    let tree = sampleTree()
    #expect(tree.path(ofFlat: flat) == path && tree.flatIndex(of: path) == flat)
}

@Test(arguments: [TabPath(item: 1), TabPath(item: 1, tab: 2), TabPath(item: 3), TabPath(item: 0, tab: 0)])
func aPathOfNoTabHasNoFlatIndex(path: TabPath) {
    #expect(sampleTree().flatIndex(of: path) == nil && sampleTree().path(ofFlat: 4) == nil)
}

/// ⌘1 to ⌘9 count these: a collapsed folder's tabs are skipped.
@Test(arguments: [(false, [0, 1, 2, 3]), (true, [0, 3])])
func visibleFlatIndexes(collapsed: Bool, shown: [Int]) {
    #expect(sampleTree(collapsed: collapsed).visibleFlatIndexes == shown)
}

/// A new tab goes right after the tab before it, in its folder; at 0 the top; at the end the root's end.
@Test(arguments: [
    (0, [treeRoot("n"), treeRoot("a"), treeFolder("work", ["b", "c"]), treeRoot("d")]),
    (1, [treeRoot("a"), treeRoot("n"), treeFolder("work", ["b", "c"]), treeRoot("d")]),
    (2, [treeRoot("a"), treeFolder("work", ["b", "n", "c"]), treeRoot("d")]),
    (3, [treeRoot("a"), treeFolder("work", ["b", "c", "n"]), treeRoot("d")]),
    (4, [treeRoot("a"), treeFolder("work", ["b", "c"]), treeRoot("d"), treeRoot("n")]),
])
func insertAtFlatIndex(flat: Int, expected: [TabTree.Item]) {
    var tree = sampleTree()
    tree.insert(treeTab("n"), atFlat: flat)
    #expect(tree.items == expected && tree.allTabs.firstIndex(of: treeTab("n")) == flat)
}

/// The last tab of a folder taken out leaves the folder, empty; past the tabs nothing is taken.
@Test func removeTabAtFlatIndex() {
    var tree = TabTree(items: [treeRoot("a"), treeFolder("work", ["b"])])
    #expect(tree.removeTab(atFlat: 1) == treeTab("b") && tree.items == [treeRoot("a"), treeFolder("work", [])])
    #expect(tree.removeTab(atFlat: 5) == nil && tree.removeTab(atFlat: 0) == treeTab("a"))
    #expect(tree.items == [treeFolder("work", [])])
}

/// Move Tab Up / Down: the tab lands at the flat index asked, by the insert rule.
@Test(arguments: [
    (3, 2, [treeRoot("a"), treeFolder("work", ["b", "d", "c"])]),
    (1, 0, [treeRoot("b"), treeRoot("a"), treeFolder("work", ["c"]), treeRoot("d")]),
    (2, 3, [treeRoot("a"), treeFolder("work", ["b"]), treeRoot("d"), treeRoot("c")]),
])
func moveTabByFlatIndex(from: Int, to: Int, expected: [TabTree.Item]) {
    var tree = sampleTree()
    tree.moveTab(fromFlat: from, toFlat: to)
    #expect(tree.items.prefix(expected.count) == expected[...] && tree.allTabs[to] == sampleTree().allTabs[from])
}

/// A drop is counted before the dragged item is taken out; `destination` gives `move` its `to`.
@Test(arguments: [
    (TabPath(item: 0), Int?.none, Int?.some(3), TabPath(item: 2)),
    (TabPath(item: 2), nil, 0, TabPath(item: 0)),
    (TabPath(item: 0), 1, nil, TabPath(item: 0, tab: 2)),
    (TabPath(item: 2), 1, 0, TabPath(item: 1, tab: 0)),
    (TabPath(item: 1, tab: 0), 1, 2, TabPath(item: 1, tab: 1)),
    (TabPath(item: 1, tab: 1), nil, 0, TabPath(item: 0)),
])
func dropDestination(from: TabPath, folder: Int?, index: Int?, to: TabPath) throws {
    let tree = sampleTree()
    #expect(tree.destination(of: from, folder: folder, index: index) == to)
    var moved = tree
    try moved.move(from: from, to: to)
    #expect(moved.allTabs.count == 4)
}

/// A tab with no address is not saved; the selection moves to the saved tab before it; folders stay.
@Test(arguments: [(0, TabPath(item: 0)), (2, TabPath(item: 1, tab: 0)), (3, TabPath(item: 1, tab: 0))])
func captureLeavesOutTabsWithoutAnAddress(selected: Int, path: TabPath) {
    let work = TreeFolder<SessionTab?>(name: "work", tabs: [nil, treeTab("c")])
    let tree = Tree<SessionTab?>(items: [.tab(treeTab("a")), .folder(work), .tab(nil)])
    let session = TreeSession.capture(tree, selected: selected, sidebarWidth: 200, collapsed: false) { $0 }
    #expect(session.tree.items == [treeRoot("a"), treeFolder("work", ["c"])])
    #expect(session.selected == path)
}
