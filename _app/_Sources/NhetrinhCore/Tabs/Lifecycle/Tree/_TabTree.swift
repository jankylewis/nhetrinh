import Foundation

// P7 tab folders (hubs/product/plan/M3_V1_RELEASE.md). STUB (P7-PREP-1, DECISIONS.md D24): the types
// are real, every operation does nothing, so the tests in Tests/_NhetrinhCoreTests/Tabs/Lifecycle/Tree/
// are red until P7-BUILD-1 builds them. The app does not use this yet.

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
public struct TabFolder: Equatable, Sendable {
    public var name: String
    public var collapsed: Bool
    public var tabs: [SessionTab]

    public init(name: String, collapsed: Bool = false, tabs: [SessionTab] = []) {
        self.name = name
        self.collapsed = collapsed
        self.tabs = tabs
    }
}

/// The sidebar's ordered items, each a tab or a folder (P7).
public struct TabTree: Equatable, Sendable {
    public enum Item: Equatable, Sendable {
        case tab(SessionTab)
        case folder(TabFolder)
    }

    /// Why an operation was refused; the tree is then left as it was.
    public enum Failure: Error, Equatable {
        /// The path names no item, or no place to put one.
        case noSuchPlace
        /// The root index names a tab where a folder is needed.
        case notAFolder
        /// A folder would go inside a folder: one level only.
        case folderInFolder
        /// A folder name of nothing but spaces.
        case emptyName
    }

    public var items: [Item]

    public init(items: [Item] = []) {
        self.items = items
    }

    /// Every tab at the root, in order: what a version 1 session becomes.
    public init(tabs: [SessionTab]) {
        self.items = []
    }

    /// Every tab, top to bottom, folders opened.
    public var allTabs: [SessionTab] { [] }

    /// The tabs a user sees, top to bottom: a collapsed folder hides its tabs (⌘1 to ⌘9 count these).
    public var visibleTabs: [SessionTab] { [] }

    /// A new empty, open folder named `name` (spaces trimmed) at root index `index`.
    public mutating func addFolder(named name: String, at index: Int) throws {}

    /// The folder at root index `index` gets the name `name` (spaces trimmed).
    public mutating func rename(folder index: Int, to name: String) throws {}

    /// Collapse or open the folder at root index `index`.
    public mutating func setCollapsed(_ collapsed: Bool, folder index: Int) throws {}

    /// Move the tab or folder at `from` to `to`: into a folder, out of one, inside one, or along the root.
    public mutating func move(from: TabPath, to: TabPath) throws {}

    /// Delete the folder at root index `index`: its tabs go to the root in its place, in order. No tab closes.
    public mutating func deleteFolder(at index: Int) throws {}
}
