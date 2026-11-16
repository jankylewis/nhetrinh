import Foundation

// P7-FIX-1 (REVIEW_P7 P1, P2, P4 rulings); tests in TreeFlatTests.swift and TabTreeMoveTests.swift.

extension Tree {
    /// Reopen a closed tab at `path`, where it was. In a folder: back in the folder named `folder` (at
    /// `path.item`, else wherever that folder is now) at its index, clamped; when no folder has that name
    /// (deleted), at the root where the folder's tabs went. A root tab: at its root index, clamped.
    /// The tab's new path.
    @discardableResult
    public mutating func reinsert(_ tab: Element, at path: TabPath, folder: String?) -> TabPath {
        guard let index = path.tab, let folder else {
            let root = min(max(0, path.item), items.count)
            items.insert(.tab(tab), at: root)
            return TabPath(item: root)
        }
        guard let home = folderIndex(named: folder, near: path.item), case .folder(var box) = items[home] else {
            let root = min(max(0, path.item + index), items.count)  // the folder is gone: where its tabs went
            items.insert(.tab(tab), at: root)
            return TabPath(item: root)
        }
        let place = min(max(0, index), box.tabs.count)
        box.tabs.insert(tab, at: place)
        items[home] = .folder(box)
        return TabPath(item: home, tab: place)
    }

    /// The folder named `name`: the one at root index `near` first, else the first anywhere.
    private func folderIndex(named name: String, near: Int) -> Int? {
        if (try? folder(at: near))?.name == name { return near }
        return items.indices.first { (try? folder(at: $0))?.name == name }
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
    /// the ends; a tab in a collapsed folder is skipped, and a hidden `from` steps to its visible neighbour.
    /// Nil when no tab is visible.
    public func visibleStep(from: Int, by step: Int) -> Int? {
        let shown = visibleFlatIndexes
        guard let first = shown.first, let last = shown.last else { return nil }
        return step > 0 ? shown.first { $0 > from } ?? first : shown.last { $0 < from } ?? last
    }

    /// Move Tab Up / Down: one row within its container. At a folder's edge a tab steps out to the root,
    /// next to the folder; a root tab passes a folder whole and never enters it. Nil when it cannot move.
    @discardableResult
    public mutating func step(_ path: TabPath, up: Bool) -> TabPath? {
        guard items.indices.contains(path.item) else { return nil }
        guard let index = path.tab else {
            guard case .tab = items[path.item] else { return nil }  // a folder moves by a drag only
            let to = path.item + (up ? -1 : 1)
            guard items.indices.contains(to) else { return nil }
            items.swapAt(path.item, to)
            return TabPath(item: to)
        }
        guard case .folder(var box) = items[path.item], box.tabs.indices.contains(index) else { return nil }
        let to = index + (up ? -1 : 1)
        if box.tabs.indices.contains(to) {
            box.tabs.swapAt(index, to)
            items[path.item] = .folder(box)
            return TabPath(item: path.item, tab: to)
        }
        let tab = box.tabs.remove(at: index)  // the folder's edge: out to the root, next to the folder
        items[path.item] = .folder(box)
        let root = up ? path.item : path.item + 1
        items.insert(.tab(tab), at: root)
        return TabPath(item: root)
    }
}

extension TreeSession {
    /// No tab to restore: one home tab, at the root's end, selected; the folders stay, even empty, and the
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
