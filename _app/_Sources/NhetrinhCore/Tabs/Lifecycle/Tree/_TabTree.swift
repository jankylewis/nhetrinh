import Foundation

// P7 tab folders (hubs/product/plan/M3_V1_RELEASE.md); red first in P7-PREP-1 (DECISIONS.md D24), built in
// P7-BUILD-1. Tests: Tests/_NhetrinhCoreTests/Tabs/Lifecycle/Tree/. The session holds a `TabTree`; the app
// holds a `Tree` of its own tabs, so both share every operation. Flat-index helpers: TreeFlat.swift.

/// Where an item is: a root item (`tab` nil), or tab `tab` inside the folder at root index `item`.
/// For a move it is the place after the moved item has been taken out.
public struct TabPath: Codable, Equatable, Hashable, Sendable {
    public var item: Int
    public var tab: Int?

    public init(item: Int, tab: Int? = nil) {
        self.item = item
        self.tab = tab
    }
}

/// A folder: a name, collapsed or not, and its tabs. It holds tabs only: one level, never a folder.
public struct TreeFolder<Element> {
    public var name: String
    public var collapsed: Bool
    public var tabs: [Element]

    public init(name: String, collapsed: Bool = false, tabs: [Element] = []) {
        self.name = name
        self.collapsed = collapsed
        self.tabs = tabs
    }
}

extension TreeFolder: Equatable where Element: Equatable {}
extension TreeFolder: Sendable where Element: Sendable {}
extension TreeFolder: Codable where Element: Codable {}

/// Why an operation was refused; the tree is then left as it was.
public enum TreeFailure: Error, Equatable, Sendable {
    /// The path names no item, or no place to put one.
    case noSuchPlace
    /// The root index names a tab where a folder is needed.
    case notAFolder
    /// A folder would go inside a folder: one level only.
    case folderInFolder
    /// A folder name of nothing but spaces.
    case emptyName
}

/// The sidebar's ordered items, each a tab or a folder (P7).
public struct Tree<Element> {
    public typealias Failure = TreeFailure

    public enum Item {
        case tab(Element)
        case folder(TreeFolder<Element>)
    }

    public var items: [Item]

    public init(items: [Item] = []) {
        self.items = items
    }

    /// Every tab at the root, in order: what a version 1 session becomes.
    public init(tabs: [Element]) {
        self.items = tabs.map { .tab($0) }
    }

    /// A new empty, open folder named `name` (spaces trimmed) at root index `index`.
    public mutating func addFolder(named name: String, at index: Int) throws {
        let name = try Self.trimmed(name)
        guard (0...items.count).contains(index) else { throw Failure.noSuchPlace }
        items.insert(.folder(TreeFolder(name: name)), at: index)
    }

    /// The folder at root index `index` gets the name `name` (spaces trimmed).
    public mutating func rename(folder index: Int, to name: String) throws {
        var folder = try self.folder(at: index)
        folder.name = try Self.trimmed(name)
        items[index] = .folder(folder)
    }

    /// Collapse or open the folder at root index `index`.
    public mutating func setCollapsed(_ collapsed: Bool, folder index: Int) throws {
        var folder = try self.folder(at: index)
        folder.collapsed = collapsed
        items[index] = .folder(folder)
    }

    /// Delete the folder at root index `index`: its tabs go to the root in its place, in order. No tab closes.
    public mutating func deleteFolder(at index: Int) throws {
        let folder = try self.folder(at: index)
        items.replaceSubrange(index...index, with: folder.tabs.map { .tab($0) })
    }

    /// Move the tab or folder at `from` to `to`: into a folder, out of one, inside one, or along the root.
    public mutating func move(from: TabPath, to: TabPath) throws {
        var rest = self
        let moving = try rest.take(from)
        if let tab = to.tab {
            guard case .tab(let element) = moving else { throw Failure.folderInFolder }
            var folder = try rest.folder(at: to.item)
            guard (0...folder.tabs.count).contains(tab) else { throw Failure.noSuchPlace }
            folder.tabs.insert(element, at: tab)
            rest.items[to.item] = .folder(folder)
        } else {
            guard (0...rest.items.count).contains(to.item) else { throw Failure.noSuchPlace }
            rest.items.insert(moving, at: to.item)
        }
        self = rest
    }

    /// The folder at root index `index`.
    public func folder(at index: Int) throws -> TreeFolder<Element> {
        guard items.indices.contains(index) else { throw Failure.noSuchPlace }
        guard case .folder(let folder) = items[index] else { throw Failure.notAFolder }
        return folder
    }

    /// Take out the item at `path`: a root item, or a tab of a folder.
    private mutating func take(_ path: TabPath) throws -> Item {
        guard let tab = path.tab else {
            guard items.indices.contains(path.item) else { throw Failure.noSuchPlace }
            return items.remove(at: path.item)
        }
        var folder = try self.folder(at: path.item)
        guard folder.tabs.indices.contains(tab) else { throw Failure.noSuchPlace }
        let element = folder.tabs.remove(at: tab)
        items[path.item] = .folder(folder)
        return .tab(element)
    }

    private static func trimmed(_ name: String) throws -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw Failure.emptyName }
        return trimmed
    }
}

extension Tree.Item: Equatable where Element: Equatable {}
extension Tree.Item: Sendable where Element: Sendable {}
extension Tree: Equatable where Element: Equatable {}
extension Tree: Sendable where Element: Sendable {}

/// The session's tree: tabs as they are saved.
public typealias TabTree = Tree<SessionTab>
public typealias TabFolder = TreeFolder<SessionTab>
