import Foundation

// P2 (hubs/product/plan/M1_DAILY_DRIVER.md); tests in _TabOrderTests.swift.

/// The index math of reordering tabs: a dragged row, Tabs > Move Tab Up / Move Tab Down.
public enum TabOrder {
    /// The order after the item at `from` moves to `to`, where `to` is its index in the result.
    /// When either index is out of range, nothing moves: the order comes back unchanged.
    public static func move<Item>(_ items: [Item], from: Int, to: Int) -> [Item] {
        guard items.indices.contains(from), items.indices.contains(to), from != to else { return items }
        var moved = items
        let item = moved.remove(at: from)
        moved.insert(item, at: to)
        return moved
    }

    /// Where the item at `index` is after `move(_:from:to:)`, so the selection follows its tab.
    /// When either move index is out of range, nothing moved: `index` comes back unchanged.
    public static func index(_ index: Int, afterMoveFrom from: Int, to: Int, count: Int) -> Int {
        let range = 0..<count
        guard range.contains(from), range.contains(to) else { return index }
        if index == from { return to }
        if from < to, index > from, index <= to { return index - 1 }
        if to < from, index >= to, index < from { return index + 1 }
        return index
    }

    /// A dragged row dropped above row `droppedAbove` (the row count: below the last) lands at this
    /// index once moved: the rows after `from` move up by one.
    public static func destination(from: Int, droppedAbove: Int) -> Int {
        from < droppedAbove ? droppedAbove - 1 : droppedAbove
    }
}
