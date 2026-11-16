import Foundation

// P2 (hubs/product/plan/M1_DAILY_DRIVER.md). STUB, red first (P2-PREP-1, DECISIONS.md D24):
// the types compile, the behaviour is not built; the tests in _TabOrderTests.swift fail until P2.

/// The index math of reordering tabs: a dragged row, Tabs > Move Tab Up / Move Tab Down.
public enum TabOrder {
    /// The order after the item at `from` moves to `to`, where `to` is its index in the result.
    /// When either index is out of range, nothing moves: the order comes back unchanged.
    public static func move<Item>(_ items: [Item], from: Int, to: Int) -> [Item] {
        []  // STUB
    }

    /// Where the item at `index` is after `move(_:from:to:)`, so the selection follows its tab.
    /// When either move index is out of range, nothing moved: `index` comes back unchanged.
    public static func index(_ index: Int, afterMoveFrom from: Int, to: Int, count: Int) -> Int {
        -1  // STUB
    }
}
