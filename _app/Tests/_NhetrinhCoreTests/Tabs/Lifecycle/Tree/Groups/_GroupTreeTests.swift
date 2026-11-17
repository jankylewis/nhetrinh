import Foundation
import Testing
@testable import NhetrinhCore

// P8-GROUPS-1 (headmate request), red first: nested groups, 4 levels at most. The headmate's tree:
// a | MBing (b | FE (c | PRs (d | Feedback (e)))) | f | X (Y (y)). Moves: GroupMoveTests.swift.

typealias Names = Tree<String>

func tab(_ name: String) -> Names.Item { .tab(name) }

func group(_ name: String, collapsed: Bool = false, _ items: Names.Item...) -> Names.Item {
    .folder(TreeFolder(name: name, collapsed: collapsed, items: items))
}

/// The headmate's tree; `collapsed` names the groups shown collapsed.
func headmateTree(collapsed: Set<String> = []) -> Names {
    func box(_ name: String, _ items: Names.Item...) -> Names.Item {
        .folder(TreeFolder(name: name, collapsed: collapsed.contains(name), items: items))
    }
    let feedback = box("Feedback", tab("e"))
    let mbing = box("MBing", tab("b"), box("FE", tab("c"), box("PRs", tab("d"), feedback)))
    return Names(items: [tab("a"), mbing, tab("f"), box("X", box("Y", tab("y")))])
}

/// The tree on one line: a tab is its name, a group `name(items)`, a collapsed one `name*(items)`.
func outline(_ tree: Names) -> String {
    func line(_ items: [Names.Item]) -> String {
        items.map { item in
            switch item {
            case .tab(let name): return name
            case .folder(let group): return group.name + (group.collapsed ? "*" : "") + "(" + line(group.items) + ")"
            }
        }.joined(separator: " ")
    }
    return line(tree.items)
}

let headmateLine = "a MBing(b FE(c PRs(d Feedback(e)))) f X(Y(y))"

@Test func theHeadmateTreeIsFourLevelsDeep() {
    let tree = headmateTree()
    #expect(outline(tree) == headmateLine && tree.depth == GroupDepth.max && GroupDepth.max == 4)
    #expect(tree.groupPaths.map(\.indexes) == [[1], [1, 1], [1, 1, 1], [1, 1, 1, 1], [3], [3, 0]])
    #expect(tree.groupNames(along: [1, 1, 1, 1, 0]) == ["MBing", "FE", "PRs", "Feedback"])
    #expect(tree.allTabs == ["a", "b", "c", "d", "e", "f", "y"])
}

/// New Group… (the root), New Group Inside… (a group): a 5th level is refused with a reason.
@Test(arguments: [
    ([Int](), 0, "G() " + headmateLine),
    ([1, 1, 1], 2, "a MBing(b FE(c PRs(d Feedback(e) G()))) f X(Y(y))"),
    ([1, 1, 1, 1], 1, "tooDeep"), ([0], 0, "notAFolder"), ([1, 9], 0, "noSuchPlace"),
] as [([Int], Int, String)])
func newGroupInside(parent: [Int], index: Int, expected: String) {
    var tree = headmateTree()
    do {
        try tree.addGroup(named: " G ", in: parent, at: index)
        #expect(outline(tree) == expected)
    } catch {
        #expect("\(error)" == expected && outline(tree) == headmateLine)
    }
}

@Test func theRefusalSaysWhy() {
    #expect(TreeFailure.tooDeep.reason == "Groups go 4 levels deep at most.")
    #expect(TreeFailure.intoItself.reason.contains("into itself"))
}

/// New Group from Selected Tab: the item goes into a new group in its place, unless that is too deep.
@Test(arguments: [
    ([0], "G(a) MBing(b FE(c PRs(d Feedback(e)))) f X(Y(y))"),
    ([1, 1, 1, 0], "a MBing(b FE(c PRs(G(d) Feedback(e)))) f X(Y(y))"),
    ([1, 1, 1, 1, 0], "tooDeep"), ([1, 1, 1], "tooDeep"), ([1, 1], "tooDeep"), ([3, 0], "a MBing(b FE(c PRs(d "
        + "Feedback(e)))) f X(G(Y(y)))"), ([9], "noSuchPlace"),
] as [([Int], String)])
func newGroupFromATab(path: [Int], expected: String) {
    var tree = headmateTree()
    do {
        try tree.wrap(TabPath(path), inGroupNamed: "G")
        #expect(outline(tree) == expected)
    } catch {
        #expect("\(error)" == expected && outline(tree) == headmateLine)
    }
}

/// Ungroup: its tabs and groups move up one level in its place; no tab closes.
@Test(arguments: [
    ([1, 1], "a MBing(b c PRs(d Feedback(e))) f X(Y(y))"),
    ([1, 1, 1, 1], "a MBing(b FE(c PRs(d e))) f X(Y(y))"),
    ([1], "a b FE(c PRs(d Feedback(e))) f X(Y(y))"),
])
func ungroupMovesItsItemsUp(path: [Int], expected: String) throws {
    var tree = headmateTree()
    try tree.ungroup(at: TabPath(path))
    #expect(outline(tree) == expected && tree.allTabs == headmateTree().allTabs)
}

/// Close Group takes the group out with all inside; rename and collapse reach any level.
@Test func closeRenameCollapseAtDepth() throws {
    var tree = headmateTree()
    try tree.rename(group: TabPath([1, 1, 1]), to: "Pull requests")
    try tree.setCollapsed(true, group: TabPath([1, 1]))
    let closed = try tree.removeGroup(at: TabPath([1, 1, 1, 1]))
    #expect(closed == TreeFolder(name: "Feedback", tabs: ["e"]))
    #expect(outline(tree) == "a MBing(b FE*(c Pull requests(d))) f X(Y(y))")
    #expect(throws: TreeFailure.notAFolder) { try tree.removeGroup(at: TabPath([0])) }
}

/// ⌘1 to ⌘9 skip a tab when any group above it is collapsed.
@Test(arguments: [
    (Set<String>(), [0, 1, 2, 3, 4, 5, 6]), (["FE"], [0, 1, 5, 6]), (["Feedback"], [0, 1, 2, 3, 5, 6]),
    (["MBing", "Feedback"], [0, 5, 6]), (["Y"], [0, 1, 2, 3, 4, 5]),
] as [(Set<String>, [Int])])
func aCollapsedAncestorHidesATab(collapsed: Set<String>, shown: [Int]) {
    #expect(headmateTree(collapsed: collapsed).visibleFlatIndexes == shown)
}

/// The flat list and the paths agree at any depth.
@Test(arguments: [(3, [1, 1, 1, 0]), (4, [1, 1, 1, 1, 0]), (6, [3, 0, 0])])
func flatIndexAndPathAgreeAtDepth(flat: Int, path: [Int]) {
    let tree = headmateTree()
    #expect(tree.path(ofFlat: flat) == TabPath(path) && tree.flatIndex(of: TabPath(path)) == flat)
}

/// A new tab goes right after the tab before it, in that tab's group, at any depth.
@Test(arguments: [(4, "a MBing(b FE(c PRs(d n Feedback(e)))) f X(Y(y))"),
                  (5, "a MBing(b FE(c PRs(d Feedback(e n)))) f X(Y(y))")])
func aNewTabGoesAfterTheTabBeforeIt(flat: Int, expected: String) {
    var tree = headmateTree()
    tree.insert("n", atFlat: flat)
    #expect(outline(tree) == expected && tree.allTabs[flat] == "n")
    #expect(tree.removeTab(atFlat: flat) == "n" && outline(tree) == headmateLine)
}
