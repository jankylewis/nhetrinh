import Foundation

// P7: the tree seen as a flat list of tabs, top to bottom, groups opened (at any depth since
// P8-GROUPS-1). The app's tab index (its selection, a closed tab's place, Move Tab Up / Down) counts tabs
// this way. Tests: TreeFlatTests.swift, GroupTreeTests.swift.

extension Tree {
    /// One tab as the flat list holds it: its path, and whether a collapsed group above it hides it.
    struct FlatTab {
        let path: TabPath
        let tab: Element
        let hidden: Bool
    }

    /// Every tab, top to bottom, groups opened.
    var flat: [FlatTab] {
        func walk(_ items: [Item], _ prefix: [Int], _ hidden: Bool, _ out: inout [FlatTab]) {
            for (index, item) in items.enumerated() {
                switch item {
                case .tab(let tab): out.append(FlatTab(path: TabPath(prefix + [index]), tab: tab, hidden: hidden))
                case .folder(let group): walk(group.items, prefix + [index], hidden || group.collapsed, &out)
                }
            }
        }
        var out: [FlatTab] = []
        walk(items, [], false, &out)
        return out
    }

    /// Every tab, top to bottom, groups opened.
    public var allTabs: [Element] { flat.map(\.tab) }

    /// The tabs a user sees, top to bottom: a collapsed group hides its tabs (⌘1 to ⌘9 count these).
    public var visibleTabs: [Element] { flat.filter { !$0.hidden }.map(\.tab) }

    /// The flat index of every tab a user sees, top to bottom: none of its groups is collapsed.
    public var visibleFlatIndexes: [Int] { flat.enumerated().filter { !$0.element.hidden }.map(\.offset) }

    /// The path of the tab at flat index `index`; nil past the tabs.
    public func path(ofFlat index: Int) -> TabPath? {
        let all = flat
        return all.indices.contains(index) ? all[index].path : nil
    }

    /// The flat index of the tab at `path`; nil when it names no tab (a group, or nothing).
    public func flatIndex(of path: TabPath) -> Int? { flat.firstIndex { $0.path == path } }

    /// A new tab at flat index `index`: right after the tab before it, in that tab's group or at the root;
    /// at 0 the root's top; at the end (or past it) the root's end, never inside the last group.
    public mutating func insert(_ tab: Element, atFlat index: Int) {
        guard index > 0, index < allTabs.count, let before = path(ofFlat: index - 1) else {
            return index <= 0 ? items.insert(.tab(tab), at: 0) : items.append(.tab(tab))
        }
        _ = try? edit(before.parent) { $0.insert(.tab(tab), at: before.last + 1) }
    }

    /// Take out the tab at flat index `index`; its groups stay, even empty. Nil past the tabs.
    @discardableResult
    public mutating func removeTab(atFlat index: Int) -> Element? {
        guard let path = path(ofFlat: index), case .tab(let tab)? = try? take(path) else { return nil }
        return tab
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
        Tree<Other>(items: Self.compactMap(items, transform))
    }

    static func compactMap<Other>(_ items: [Item], _ transform: (Element) -> Other?) -> [Tree<Other>.Item] {
        items.compactMap { item -> Tree<Other>.Item? in
            switch item {
            case .tab(let tab): return transform(tab).map { .tab($0) }
            case .folder(let group):
                return .folder(TreeFolder(name: group.name, collapsed: group.collapsed,
                                          items: compactMap(group.items, transform)))
            }
        }
    }
}
