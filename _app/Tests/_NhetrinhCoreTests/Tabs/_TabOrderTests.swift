import Testing
@testable import NhetrinhCore

// P2 tests (hubs/product/plan/M1_DAILY_DRIVER.md), red first (P2-PREP-1):
// `TabOrder` is a stub, so every case here fails until P2 builds it.

private let tabs = ["a", "b", "c", "d", "e"]

@Test(arguments: [
    (1, 3, ["a", "c", "d", "b", "e"]),
    (0, 4, ["b", "c", "d", "e", "a"]),
    (2, 3, ["a", "b", "d", "c", "e"]),  // Move Tab Down
])
func moveForward(from: Int, to: Int, expected: [String]) {
    #expect(TabOrder.move(tabs, from: from, to: to) == expected)
}

@Test(arguments: [
    (3, 1, ["a", "d", "b", "c", "e"]),
    (4, 0, ["e", "a", "b", "c", "d"]),
    (2, 1, ["a", "c", "b", "d", "e"]),  // Move Tab Up
])
func moveBackward(from: Int, to: Int, expected: [String]) {
    #expect(TabOrder.move(tabs, from: from, to: to) == expected)
}

@Test(arguments: [0, 2, 4])
func moveToTheSameIndexChangesNothing(index: Int) {
    #expect(TabOrder.move(tabs, from: index, to: index) == tabs)
}

/// Move Tab Up on the first row and Move Tab Down on the last are out of range too.
@Test(arguments: [(5, 0), (-1, 2), (0, 5), (2, -1), (0, -1), (4, 5)])
func moveOutOfRangeChangesNothing(from: Int, to: Int) {
    #expect(TabOrder.move(tabs, from: from, to: to) == tabs)
}

@Test(arguments: [
    (1, 1, 3, 3), (2, 1, 3, 1), (3, 1, 3, 2), (0, 1, 3, 0), (4, 1, 3, 4),  // forward
    (3, 3, 1, 1), (1, 3, 1, 2), (2, 3, 1, 3), (0, 3, 1, 0), (4, 3, 1, 4),  // backward
    (2, 2, 2, 2), (2, 5, 0, 2), (1, 0, -1, 1),                             // same, out of range
])
func selectionFollowsItsTab(index: Int, from: Int, to: Int, expected: Int) {
    #expect(TabOrder.index(index, afterMoveFrom: from, to: to, count: tabs.count) == expected)
}

/// The two functions agree: every tab is found where `index(_:afterMoveFrom:to:count:)` says.
@Test(arguments: [(1, 3), (3, 1), (0, 4), (4, 0), (2, 2), (5, 0)])
func indexAgreesWithMove(from: Int, to: Int) {
    let moved = TabOrder.move(tabs, from: from, to: to)
    let found = tabs.indices.map { TabOrder.index($0, afterMoveFrom: from, to: to, count: tabs.count) }
    #expect(found.map { moved.indices.contains($0) ? moved[$0] : "?" } == tabs)
}
