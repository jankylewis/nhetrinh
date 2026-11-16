import Foundation
import Testing
@testable import NhetrinhCore

// P7 moves, red first on stubs (P7-PREP-1, DECISIONS.md D24). The tree is a | work (b, c) | d.
// `to` is the place after the moved item was taken out (TabPath). Refused moves: a | work (b, c) | home (e).

private func at(_ item: Int, _ tab: Int? = nil) -> TabPath { TabPath(item: item, tab: tab) }

struct MoveCase: CustomTestStringConvertible {
    let testDescription: String
    let from: TabPath
    let to: TabPath
    let expected: [TabTree.Item]
}

let moveCases = [
    MoveCase(testDescription: "a root tab into a folder, first", from: at(0), to: at(0, 0),
             expected: [treeFolder("work", ["a", "b", "c"]), treeRoot("d")]),
    MoveCase(testDescription: "a root tab into a folder, last", from: at(2), to: at(1, 2),
             expected: [treeRoot("a"), treeFolder("work", ["b", "c", "d"])]),
    MoveCase(testDescription: "a tab out of a folder, to the top", from: at(1, 0), to: at(0),
             expected: [treeRoot("b"), treeRoot("a"), treeFolder("work", ["c"]), treeRoot("d")]),
    MoveCase(testDescription: "a tab out of a folder, to the end", from: at(1, 1), to: at(3),
             expected: [treeRoot("a"), treeFolder("work", ["b"]), treeRoot("d"), treeRoot("c")]),
    MoveCase(testDescription: "a tab inside its folder", from: at(1, 0), to: at(1, 1),
             expected: [treeRoot("a"), treeFolder("work", ["c", "b"]), treeRoot("d")]),
    MoveCase(testDescription: "a root tab along the root", from: at(0), to: at(2),
             expected: [treeFolder("work", ["b", "c"]), treeRoot("d"), treeRoot("a")]),
    MoveCase(testDescription: "a folder along the root, with its tabs", from: at(1), to: at(0),
             expected: [treeFolder("work", ["b", "c"]), treeRoot("a"), treeRoot("d")]),
]

@Test(arguments: moveCases)
func moveTab(run: MoveCase) throws {
    var tree = sampleTree()
    try tree.move(from: run.from, to: run.to)
    #expect(tree.items == run.expected)
    #expect(tree.allTabs.count == 4, "a move never closes or copies a tab")
}

/// The last tab moved out leaves the folder, empty: a folder goes only by Delete Folder.
@Test func movingTheLastTabOutKeepsAnEmptyFolder() throws {
    var tree = TabTree(items: [treeFolder("work", ["b"]), treeRoot("d")])
    try tree.move(from: at(0, 0), to: at(2))
    #expect(tree.items == [treeFolder("work", []), treeRoot("d"), treeRoot("b")])
}

/// A collapsed folder takes a tab and stays collapsed (the sidebar then marks it, P7 app side).
@Test func aCollapsedFolderTakesATab() throws {
    var tree = sampleTree(collapsed: true)
    try tree.move(from: at(0), to: at(0, 2))
    #expect(tree.items == [treeFolder("work", ["b", "c", "a"], collapsed: true), treeRoot("d")])
}

struct RefusedMove: CustomTestStringConvertible {
    let testDescription: String
    let from: TabPath
    let to: TabPath
    let failure: TabTree.Failure
}

/// One level only: a folder never goes inside a folder. A refused move leaves the tree as it was.
let refusedMoves = [
    RefusedMove(testDescription: "a folder into the next one", from: at(1), to: at(1, 0), failure: .folderInFolder),
    RefusedMove(testDescription: "a folder into the one before", from: at(2), to: at(1, 0), failure: .folderInFolder),
    RefusedMove(testDescription: "no item there", from: at(5), to: at(0), failure: .noSuchPlace),
    RefusedMove(testDescription: "no tab there in the folder", from: at(1, 9), to: at(0), failure: .noSuchPlace),
    RefusedMove(testDescription: "a tab path inside a root tab", from: at(0, 0), to: at(1), failure: .notAFolder),
    RefusedMove(testDescription: "past the root's end", from: at(0), to: at(9), failure: .noSuchPlace),
    RefusedMove(testDescription: "past the folder's end", from: at(0), to: at(0, 5), failure: .noSuchPlace),
    RefusedMove(testDescription: "into a root tab", from: at(1, 0), to: at(0, 0), failure: .notAFolder),
]

@Test(arguments: refusedMoves)
func moveRefuses(run: RefusedMove) {
    var tree = TabTree(items: [treeRoot("a"), treeFolder("work", ["b", "c"]), treeFolder("home", ["e"])])
    let before = tree
    #expect(throws: run.failure) { try tree.move(from: run.from, to: run.to) }
    #expect(tree == before)
}
