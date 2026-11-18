import Foundation

// P7: the tree seen as a flat list of tabs, top to bottom, folders opened. The app's tab index (its
// selection, a closed tab's place, Move Tab Up / Down) counts tabs this way. Tests: TreeFlatTests.swift.

extension Tree {
    /// Every tab, top to bottom, folders opened.
    public var allTabs: [Element] {
        items.flatMap { item -> [Element] in
            switch item {
            case .tab(let tab): return [tab]
            case .folder(let folder): return folder.tabs
            }
        }
    }

    /// The tabs a user sees, top to bottom: a collapsed folder hides its tabs (⌘1 to ⌘9 count these).
    public var visibleTabs: [Element] {
        let all = allTabs
        return visibleFlatIndexes.map { all[$0] }
    }

    /// The flat index of every tab a user sees, top to bottom.
    public var visibleFlatIndexes: [Int] {
        var flat = 0
        var shown: [Int] = []
        for item in items {
            switch item {
            case .tab:
                shown.append(flat)
                flat += 1
            case .folder(let folder):
                if !folder.collapsed { shown += flat..<(flat + folder.tabs.count) }
                flat += folder.tabs.count
            }
        }
        return shown
    }

    /// The path of the tab at flat index `index`; nil past the tabs.
    public func path(ofFlat index: Int) -> TabPath? {
        var flat = 0
        for (root, item) in items.enumerated() {
            switch item {
            case .tab:
                if flat == index { return TabPath(item: root) }
                flat += 1
            case .folder(let folder):
                if (flat..<(flat + folder.tabs.count)).contains(index) { return TabPath(item: root, tab: index - flat) }
                flat += folder.tabs.count
            }
        }
        return nil
    }

    /// The flat index of the tab at `path`; nil when it names no tab (a folder, or nothing).
    public func flatIndex(of path: TabPath) -> Int? {
        guard items.indices.contains(path.item) else { return nil }
        let before = Tree(items: Array(items[..<path.item])).allTabs.count
        switch (items[path.item], path.tab) {
        case (.tab, nil): return before
        case (.folder(let folder), .some(let tab)) where folder.tabs.indices.contains(tab): return before + tab
        default: return nil
        }
    }

    /// A new tab at flat index `index`: right after the tab before it, in that tab's folder or at the
    /// root; at 0 the root's top; at the end (or past it) the root's end, never inside the last folder.
    public mutating func insert(_ tab: Element, atFlat index: Int) {
        guard index > 0, index < allTabs.count, let before = path(ofFlat: index - 1) else {
            return index <= 0 ? items.insert(.tab(tab), at: 0) : items.append(.tab(tab))
        }
        guard let place = before.tab, case .folder(var folder) = items[before.item] else {
            return items.insert(.tab(tab), at: before.item + 1)
        }
        folder.tabs.insert(tab, at: place + 1)
        items[before.item] = .folder(folder)
    }

    /// Take out the tab at flat index `index`; its folder stays, even empty. Nil past the tabs.
    @discardableResult
    public mutating func removeTab(atFlat index: Int) -> Element? {
        guard let path = path(ofFlat: index) else { return nil }
        guard let tab = path.tab, case .folder(var folder) = items[path.item] else {
            guard case .tab(let element) = items.remove(at: path.item) else { return nil }
            return element
        }
        let element = folder.tabs.remove(at: tab)
        items[path.item] = .folder(folder)
        return element
    }

    /// Move the tab at flat index `from` to flat index `to` (its index once moved), as `insert` places it.
    public mutating func moveTab(fromFlat from: Int, toFlat to: Int) {
        let count = allTabs.count
        guard (0..<count).contains(from), (0..<count).contains(to), from != to,
              let tab = removeTab(atFlat: from) else { return }
        insert(tab, atFlat: to)
    }

    /// The same tree with every tab changed by `transform`; a tab it maps to nil is left out.
    public func compactMapTabs<Other>(_ transform: (Element) -> Other?) -> Tree<Other> {
        Tree<Other>(items: items.compactMap { item -> Tree<Other>.Item? in
            switch item {
            case .tab(let tab): return transform(tab).map { .tab($0) }
            case .folder(let folder):
                return .folder(TreeFolder(name: folder.name, collapsed: folder.collapsed,
                                          tabs: folder.tabs.compactMap(transform)))
            }
        })
    }

    /// A drop: the item at `from` dropped into the folder at root index `folder` (nil: the root) at
    /// `index` (nil: the folder's end), both counted before `from` is taken out. The `to` of `move`.
    public func destination(of from: TabPath, folder: Int?, index: Int?) -> TabPath {
        let rootTaken = from.tab == nil
        guard let folder else {
            let place = index ?? items.count
            return TabPath(item: rootTaken && from.item < place ? place - 1 : place)
        }
        let count = (try? self.folder(at: folder).tabs.count) ?? 0
        var place = index ?? count
        if !rootTaken, from.item == folder, let tab = from.tab, tab < place { place -= 1 }
        return TabPath(item: rootTaken && from.item < folder ? folder - 1 : folder, tab: place)
    }
}
