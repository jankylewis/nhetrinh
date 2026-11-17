import Foundation

// P8-GROUPS-1 (headmate request): nested groups, created, renamed, collapsed, ungrouped, closed and moved
// with all inside. Every create or move past `GroupDepth.max`, or of a group into itself, is refused.
// Tests: _TabTreeTests.swift, TabTreeMoveTests.swift, GroupTreeTests.swift.

/// How deep groups go: a top group and 3 nested levels (headmate). The one constant.
public enum GroupDepth {
    public static let max = 4
}

/// Why an operation was refused; the tree is then left as it was. `reason` is what the user reads.
public enum TreeFailure: Error, Equatable, Sendable {
    /// The path names no item, or no place to put one.
    case noSuchPlace
    /// The path names a tab where a group is needed.
    case notAFolder
    /// A group would be more than `GroupDepth.max` levels deep.
    case tooDeep
    /// A group would go inside itself or a group inside it.
    case intoItself
    /// A group name of nothing but spaces.
    case emptyName

    public var reason: String {
        switch self {
        case .noSuchPlace: return "That place is no longer in the sidebar."
        case .notAFolder: return "That row is a tab, not a group."
        case .tooDeep: return "Groups go \(GroupDepth.max) levels deep at most."
        case .intoItself: return "A group cannot move into itself or into a group inside it."
        case .emptyName: return "A group needs a name."
        }
    }
}

extension Tree {
    /// Whether a new group can be made in the group at `parent` (empty: the root): it is there, not too deep.
    public func checkNewGroup(in parent: [Int]) throws {
        _ = try container(parent)
        guard parent.count < GroupDepth.max else { throw Failure.tooDeep }
    }

    /// A new empty, open group named `name` (spaces trimmed) at `index` of the group at `parent` (the root).
    public mutating func addGroup(named name: String, in parent: [Int] = [], at index: Int) throws {
        let name = try Self.trimmed(name)
        try checkNewGroup(in: parent)
        try edit(parent) { items in
            guard (0...items.count).contains(index) else { throw Failure.noSuchPlace }
            items.insert(.folder(TreeFolder(name: name)), at: index)
        }
    }

    /// New Group from Selected Tab: the item at `path` goes into a new open group named `name`, in its place.
    public mutating func wrap(_ path: TabPath, inGroupNamed name: String) throws {
        let name = try Self.trimmed(name)
        guard let item = item(at: path) else { throw Failure.noSuchPlace }
        guard path.parent.count + 1 + item.height <= GroupDepth.max else { throw Failure.tooDeep }
        try edit(path.parent) { $0[path.last] = .folder(TreeFolder(name: name, items: [item])) }
    }

    /// The group at `path` gets the name `name` (spaces trimmed).
    public mutating func rename(group path: TabPath, to name: String) throws {
        let name = try Self.trimmed(name)
        try editGroup(path) { $0.name = name }
    }

    /// Collapse or open the group at `path`.
    public mutating func setCollapsed(_ collapsed: Bool, group path: TabPath) throws {
        try editGroup(path) { $0.collapsed = collapsed }
    }

    /// Ungroup: the group at `path` goes; its tabs and groups move up one level, in its place. No tab closes.
    public mutating func ungroup(at path: TabPath) throws {
        let group = try self.group(at: path)
        try edit(path.parent) { $0.replaceSubrange(path.last...path.last, with: group.items) }
    }

    /// Close Group: the group at `path` is taken out with all inside, and returned.
    public mutating func removeGroup(at path: TabPath) throws -> TreeFolder<Element> {
        let group = try self.group(at: path)
        _ = try take(path)
        return group
    }

    /// Move the item at `from` to `to` (the place once it is taken out), a group with all inside.
    public mutating func move(from: TabPath, to: TabPath) throws {
        var rest = self
        let moving = try rest.take(from)
        guard !to.indexes.isEmpty else { throw Failure.noSuchPlace }
        try rest.edit(to.parent) { items in
            guard (0...items.count).contains(to.last) else { throw Failure.noSuchPlace }
            items.insert(moving, at: to.last)
        }
        guard to.parent.count + moving.height <= GroupDepth.max else { throw Failure.tooDeep }
        self = rest
    }

    /// Move the item at `from` into the group at `parent` (empty: the root) at `index` (nil: its end), both
    /// counted before it is taken out: a drop, or a Move … to menu item.
    public mutating func move(from: TabPath, into parent: [Int], at index: Int?) throws {
        try move(from: from, to: destination(of: from, into: parent, at: index))
    }

    /// The `to` of `move` for a drop into the group at `parent` at `index`, counted before `from` is taken out.
    public func destination(of from: TabPath, into parent: [Int], at index: Int?) throws -> TabPath {
        let count = try container(parent).count
        guard item(at: from) != nil else { throw Failure.noSuchPlace }
        guard Array(parent.prefix(from.indexes.count)) != from.indexes else { throw Failure.intoItself }
        var parent = parent
        var place = index ?? count
        let level = from.indexes.count - 1
        if parent == from.parent, from.last < place {
            place -= 1
        } else if parent.count > level, Array(parent.prefix(level)) == from.parent, parent[level] > from.last {
            parent[level] -= 1
        }
        return TabPath(parent + [place])
    }

    /// Every group's path, top to bottom; a group's own groups follow it.
    public var groupPaths: [TabPath] {
        func walk(_ items: [Item], _ prefix: [Int]) -> [TabPath] {
            items.enumerated().flatMap { index, item -> [TabPath] in
                guard case .folder(let group) = item else { return [] }
                return [TabPath(prefix + [index])] + walk(group.items, prefix + [index])
            }
        }
        return walk(items, [])
    }

    /// The names of the groups along `path`, top first; it stops at the first index that names no group.
    public func groupNames(along path: [Int]) -> [String] {
        path.indices.compactMap { try? group(at: TabPath(Array(path.prefix($0 + 1)))).name }
    }

    private mutating func editGroup(_ path: TabPath, _ body: (inout TreeFolder<Element>) -> Void) throws {
        _ = try group(at: path)
        try edit(path.parent) { items in
            guard case .folder(var group) = items[path.last] else { return }
            body(&group)
            items[path.last] = .folder(group)
        }
    }

    static func trimmed(_ name: String) throws -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw Failure.emptyName }
        return trimmed
    }
}
