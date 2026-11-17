import Foundation

// P7 tab folders (hubs/product/plan/M3_V1_RELEASE.md), nested groups since P8-GROUPS-1: a group holds tabs
// and groups in any order, `GroupDepth.max` levels at most. Tests: Tests/_NhetrinhCoreTests/Tabs/Lifecycle/
// Tree/. The session holds a `TabTree`; the app holds a `Tree` of its own tabs, so both share every
// operation. Group operations: TreeGroups.swift; flat-index helpers: TreeFlat.swift.

/// Where an item is: its index at the root, then its index inside each group on the way down. For a move
/// it is the place after the moved item has been taken out.
public struct TabPath: Hashable, Sendable {
    public var indexes: [Int]

    public init(_ indexes: [Int]) {
        self.indexes = indexes
    }

    /// P7's one-level path: the root item `item`, or the item `tab` of the group at root index `item`.
    public init(item: Int, tab: Int? = nil) {
        self.indexes = [item] + (tab.map { [$0] } ?? [])
    }

    /// The root index.
    public var item: Int { indexes.first ?? 0 }
    /// The index inside its group; nil for a root item.
    public var tab: Int? { indexes.count > 1 ? indexes.last : nil }
    /// The path of the group that holds it; empty for a root item.
    public var parent: [Int] { Array(indexes.dropLast()) }
    /// Its index inside its container.
    public var last: Int { indexes.last ?? 0 }
}

/// A group: a name, collapsed or not, and its items, tabs and groups in any order.
public struct TreeFolder<Element> {
    public var name: String
    public var collapsed: Bool
    public var items: [Tree<Element>.Item]

    public init(name: String, collapsed: Bool = false, items: [Tree<Element>.Item]) {
        self.name = name
        self.collapsed = collapsed
        self.items = items
    }

    /// A group of tabs only (P7's folder).
    public init(name: String, collapsed: Bool = false, tabs: [Element] = []) {
        self.init(name: name, collapsed: collapsed, items: tabs.map { .tab($0) })
    }

    /// Every tab inside, at any depth, top to bottom.
    public var allTabs: [Element] { Tree(items: items).allTabs }
}

extension TreeFolder: Equatable where Element: Equatable {}
extension TreeFolder: Sendable where Element: Sendable {}

/// The sidebar's ordered items, each a tab or a group (P7; nested since P8-GROUPS-1).
public struct Tree<Element> {
    public typealias Failure = TreeFailure

    public enum Item {
        case tab(Element)
        case folder(TreeFolder<Element>)

        /// How many group levels it holds: a tab 0, a group of tabs 1, a group in a group 2, …
        public var height: Int {
            guard case .folder(let group) = self else { return 0 }
            return 1 + (group.items.map(\.height).max() ?? 0)
        }
    }

    public var items: [Item]

    public init(items: [Item] = []) {
        self.items = items
    }

    /// Every tab at the root, in order: what a version 1 session becomes.
    public init(tabs: [Element]) {
        self.items = tabs.map { .tab($0) }
    }

    /// The deepest group level in the tree: 0 with no group.
    public var depth: Int { items.map(\.height).max() ?? 0 }

    /// The item at `path`; nil when it names none.
    public func item(at path: TabPath) -> Item? {
        guard let index = path.indexes.last, let items = try? container(path.parent),
              items.indices.contains(index) else { return nil }
        return items[index]
    }

    /// The group at `path`.
    public func group(at path: TabPath) throws -> TreeFolder<Element> {
        guard !path.indexes.isEmpty else { throw Failure.noSuchPlace }
        let items = try container(path.parent)
        guard items.indices.contains(path.last) else { throw Failure.noSuchPlace }
        guard case .folder(let group) = items[path.last] else { throw Failure.notAFolder }
        return group
    }

    /// The items of the group at `parent` (empty: the root).
    func container(_ parent: [Int]) throws -> [Item] {
        var copy = self
        return try copy.edit(parent) { $0 }
    }

    /// Run `body` on the items of the group at `parent` (empty: the root), written back afterwards.
    mutating func edit<T>(_ parent: [Int], _ body: (inout [Item]) throws -> T) throws -> T {
        try Self.edit(&items, parent[...], body)
    }

    private static func edit<T>(_ items: inout [Item], _ path: ArraySlice<Int>,
                                _ body: (inout [Item]) throws -> T) throws -> T {
        guard let first = path.first else { return try body(&items) }
        guard items.indices.contains(first) else { throw Failure.noSuchPlace }
        guard case .folder(var group) = items[first] else { throw Failure.notAFolder }
        let result = try edit(&group.items, path.dropFirst(), body)
        items[first] = .folder(group)
        return result
    }

    /// Take out the item at `path`.
    mutating func take(_ path: TabPath) throws -> Item {
        guard !path.indexes.isEmpty else { throw Failure.noSuchPlace }
        return try edit(path.parent) { items in
            guard items.indices.contains(path.last) else { throw Failure.noSuchPlace }
            return items.remove(at: path.last)
        }
    }
}

extension Tree.Item: Equatable where Element: Equatable {}
extension Tree.Item: Sendable where Element: Sendable {}
extension Tree: Equatable where Element: Equatable {}
extension Tree: Sendable where Element: Sendable {}

/// The session's tree: tabs as they are saved.
public typealias TabTree = Tree<SessionTab>
public typealias TabFolder = TreeFolder<SessionTab>
