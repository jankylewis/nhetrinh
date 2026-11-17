import Foundation

// P7-FIX-1 (REVIEW_P7 P1, P2, P4 rulings), nested since P8-GROUPS-1; tests in TreeFlatTests.swift,
// TabTreeMoveTests.swift and GroupTreeTests.swift.

extension Tree {
    /// Reopen a closed tab at `path`, where it was. `groups` names the groups along `path.parent`, top first.
    /// Each is looked for at its index, else by name in its container; when one is gone (ungrouped), its
    /// items moved up in its place, so the search goes on there. A root tab: at its root index, clamped.
    /// The tab's new path.
    @discardableResult
    public mutating func reinsert(_ tab: Element, at path: TabPath, groups: [String]) -> TabPath {
        reinsert(.tab(tab), at: path, groups: groups, recreate: false)
    }

    /// P7's call: one folder name (nil: a root tab).
    @discardableResult
    public mutating func reinsert(_ tab: Element, at path: TabPath, folder: String?) -> TabPath {
        reinsert(tab, at: path, groups: folder.map { [$0] } ?? [])
    }

    /// Reopen an item at `path` in the groups named `groups` (as `reinsert`). With `recreate`, a group that is
    /// gone, and whose next group is not where it was either, is made again, empty and open, at its old
    /// index: Close Group's reopen (P8-GROUPS-1).
    @discardableResult
    public mutating func reinsert(_ item: Item, at path: TabPath, groups: [String], recreate: Bool) -> TabPath {
        TabPath(Self.place(item, in: &items, path: path.indexes[...], groups: groups[...], recreate: recreate))
    }

    private static func place(_ item: Item, in items: inout [Item], path: ArraySlice<Int>,
                              groups: ArraySlice<String>, recreate: Bool) -> [Int] {
        let want = path.first ?? 0
        guard let name = groups.first, path.count > 1 else {
            let index = min(max(0, want), items.count)
            items.insert(item, at: index)
            return [index]
        }
        let next = want + (path.dropFirst().first ?? 0)
        var home = groupIndex(named: name, near: want, in: items)
        let holdsNext = groups.dropFirst().first.map { groupIndex(named: $0, near: next, in: items) != nil } ?? false
        if home == nil, recreate, !holdsNext {
            home = min(max(0, want), items.count)
            items.insert(.folder(TreeFolder(name: name)), at: home ?? 0)
        }
        guard let home, case .folder(var group) = items[home] else {  // gone: its items moved up, in its place
            let skipped = [next] + path.dropFirst(2)
            return place(item, in: &items, path: skipped[...], groups: groups.dropFirst(), recreate: recreate)
        }
        let inside = place(item, in: &group.items, path: path.dropFirst(), groups: groups.dropFirst(),
                           recreate: recreate)
        items[home] = .folder(group)
        return [home] + inside
    }

    /// The group named `name` in `items`: the one at `near` first, else the first one.
    private static func groupIndex(named name: String, near: Int, in items: [Item]) -> Int? {
        func named(_ index: Int) -> Bool {
            guard items.indices.contains(index), case .folder(let group) = items[index] else { return false }
            return group.name == name
        }
        return named(near) ? near : items.indices.first(where: named)
    }

    /// After the tab at flat `index` was taken out: the flat index to select. The nearest visible tab
    /// above, else below; a hidden one only when no tab is visible; nil when there is no tab.
    public func nearestVisible(afterRemoving index: Int) -> Int? {
        let shown = visibleFlatIndexes
        if let above = shown.last(where: { $0 < index }) ?? shown.first(where: { $0 >= index }) { return above }
        let count = allTabs.count
        return count == 0 ? nil : min(max(0, index), count - 1)
    }

    /// ⌃⇥ / ⌃⇧⇥: the flat index of the next (`by` 1) or previous (-1) visible tab from flat `from`, round
    /// the ends; a tab in a collapsed group is skipped, and a hidden `from` steps to its visible neighbour.
    /// Nil when no tab is visible.
    public func visibleStep(from: Int, by step: Int) -> Int? {
        let shown = visibleFlatIndexes
        guard let first = shown.first, let last = shown.last else { return nil }
        return step > 0 ? shown.first { $0 > from } ?? first : shown.last { $0 < from } ?? last
    }

    /// Move Tab Up / Down: one row within its container, passing a group whole, never into it. At a group's
    /// edge the tab steps out one level, next to the group. Nil when it cannot move (a group, the root's edge).
    @discardableResult
    public mutating func step(_ path: TabPath, up: Bool) -> TabPath? {
        guard case .tab? = item(at: path) else { return nil }  // a group moves by a drag or its menu
        let to = path.last + (up ? -1 : 1)
        if let count = try? container(path.parent).count, (0..<count).contains(to) {
            _ = try? edit(path.parent) { $0.swapAt(path.last, to) }
            return TabPath(path.parent + [to])
        }
        guard let group = path.parent.last, let tab = try? take(path) else { return nil }
        let out = TabPath(path.parent.dropLast() + [up ? group : group + 1])
        _ = try? edit(out.parent) { $0.insert(tab, at: out.last) }
        return out
    }
}

extension TreeSession {
    /// No tab to restore: one home tab, at the root's end, selected; the groups stay, even empty, and the
    /// sidebar as it was (P7-FIX-1, P3).
    func withHomeTab(_ home: URL) -> TreeSession {
        var kept = TreeSession.home(home)
        kept.tree.items = tree.items + kept.tree.items
        kept.selected = TabPath(item: kept.tree.items.count - 1)
        kept.sidebarWidth = sidebarWidth
        kept.collapsed = collapsed
        return kept
    }
}
