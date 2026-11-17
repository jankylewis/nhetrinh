import Foundation
import Testing
@testable import NhetrinhCore

// P8-GROUPS-1, red first: moves in the headmate's tree (_GroupTreeTests.swift), a drop or a Move … to item:
// into the group at `into` (empty: the root) at `at` (nil: its end), counted before the item is taken out.

struct GroupMove: CustomTestStringConvertible {
    let testDescription: String
    let from: [Int]
    let into: [Int]
    let at: Int?
    /// The tree after, or the failure's name.
    let expected: String
}

let groupMoves = [
    GroupMove(testDescription: "PRs to the top level", from: [1, 1, 1], into: [], at: nil,
              expected: "a MBing(b FE(c)) f X(Y(y)) PRs(d Feedback(e))"),
    GroupMove(testDescription: "X into FE, 4 levels", from: [3], into: [1, 1], at: nil,
              expected: "a MBing(b FE(c PRs(d Feedback(e)) X(Y(y)))) f"),
    GroupMove(testDescription: "X into PRs: 5 levels", from: [3], into: [1, 1, 1], at: nil, expected: "tooDeep"),
    GroupMove(testDescription: "Y into Feedback: 5 levels", from: [3, 0], into: [1, 1, 1, 1], at: 0,
              expected: "tooDeep"),
    GroupMove(testDescription: "MBing into itself", from: [1], into: [1], at: 0, expected: "intoItself"),
    GroupMove(testDescription: "MBing into its FE", from: [1], into: [1, 1], at: 0, expected: "intoItself"),
    GroupMove(testDescription: "FE into its Feedback", from: [1, 1], into: [1, 1, 1, 1], at: nil,
              expected: "intoItself"),
    GroupMove(testDescription: "a tab from the top into Feedback", from: [0], into: [1, 1, 1, 1], at: 0,
              expected: "MBing(b FE(c PRs(d Feedback(a e)))) f X(Y(y))"),
    GroupMove(testDescription: "a tab out of Feedback to the top", from: [1, 1, 1, 1, 0], into: [], at: 0,
              expected: "e a MBing(b FE(c PRs(d Feedback()))) f X(Y(y))"),
    GroupMove(testDescription: "a tab to the end of its own group", from: [1, 1, 0], into: [1, 1], at: nil,
              expected: "a MBing(b FE(PRs(d Feedback(e)) c)) f X(Y(y))"),
    GroupMove(testDescription: "a group along its group", from: [1, 1, 1], into: [1, 1], at: 0,
              expected: "a MBing(b FE(PRs(d Feedback(e)) c)) f X(Y(y))"),
    GroupMove(testDescription: "a tab into a tab", from: [0], into: [2], at: 0, expected: "notAFolder"),
    GroupMove(testDescription: "past a group's end", from: [0], into: [3], at: 5, expected: "noSuchPlace"),
]

@Test(arguments: groupMoves)
func moveInTheHeadmateTree(run: GroupMove) {
    var tree = headmateTree()
    do {
        try tree.move(from: TabPath(run.from), into: run.into, at: run.at)
        #expect(outline(tree) == run.expected)
        #expect(tree.allTabs.sorted() == headmateTree().allTabs.sorted(), "a move never closes or copies a tab")
    } catch {
        #expect("\(error)" == run.expected && outline(tree) == headmateLine)
    }
}

/// Move Group to > Top Level, then back into MBing > FE: the tree is as it was.
@Test func aGroupMovesOutAndBack() throws {
    var tree = headmateTree()
    try tree.move(from: TabPath([1, 1, 1]), into: [], at: nil)
    try tree.move(from: TabPath([4]), into: [1, 1], at: nil)
    #expect(outline(tree) == headmateLine)
}

/// Move Tab Up / Down at depth: a tab passes a group whole; at its group's edge it steps out one level.
@Test(arguments: [
    ([1, 1, 1, 1, 0], true, "a MBing(b FE(c PRs(d e Feedback()))) f X(Y(y))", [1, 1, 1, 1]),
    ([1, 1, 1, 1, 0], false, "a MBing(b FE(c PRs(d Feedback() e))) f X(Y(y))", [1, 1, 1, 2]),
    ([1, 1, 1, 0], false, "a MBing(b FE(c PRs(Feedback(e) d))) f X(Y(y))", [1, 1, 1, 1]),
    ([1, 1, 1], true, headmateLine, nil),
] as [([Int], Bool, String, [Int]?)])
func moveTabUpAndDownAtDepth(path: [Int], up: Bool, expected: String, placed: [Int]?) {
    var tree = headmateTree()
    #expect(tree.step(TabPath(path), up: up)?.indexes == placed && outline(tree) == expected)
}

/// Reopen Closed Tab at depth: back in its group; a group gone (ungrouped) puts it where its items went.
@Test(arguments: [(false, headmateLine), (true, "a MBing(b c PRs(d Feedback(e))) f X(Y(y))")])
func aClosedTabComesBackAtDepth(ungroupFE: Bool, expected: String) throws {
    var tree = headmateTree()
    let path = TabPath([1, 1, 1, 1, 0])
    let groups = tree.groupNames(along: path.parent)
    #expect(tree.removeTab(atFlat: 4) == "e")
    if ungroupFE { try tree.ungroup(at: TabPath([1, 1])) }
    let placed = tree.reinsert("e", at: path, groups: groups)
    #expect(outline(tree) == expected && tree.item(at: placed) == .tab("e"))
}

/// Close Group, then Reopen Closed Tab: the group comes back whole; groups on its path that are gone are
/// made again, empty and open, unless the next one moved up into their place.
@Test(arguments: [
    ([[Int]](), headmateLine), ([[1, 1, 1]], "a MBing(b FE(c PRs(Feedback(e)) d)) f X(Y(y))"),
    ([[1, 1]], "a MBing(b c PRs(d Feedback(e))) f X(Y(y))"),
    ([[1, 1, 1], [1, 1]], "a MBing(b FE(PRs(Feedback(e))) c d) f X(Y(y))"),
])
func aClosedGroupComesBackWhole(ungrouped: [[Int]], expected: String) throws {
    var tree = headmateTree()
    let path = TabPath([1, 1, 1, 1])
    let groups = tree.groupNames(along: path.parent)
    let closed = try tree.removeGroup(at: path)
    for gone in ungrouped { try tree.ungroup(at: TabPath(gone)) }
    let placed = tree.reinsert(.folder(closed), at: path, groups: groups, recreate: true)
    #expect(outline(tree) == expected && (try? tree.group(at: placed).name) == "Feedback")
}
