import AppKit
import NhetrinhCore

/// What the sidebar shows, top first: a tab, or a group with its items (P7; nested since P8-GROUPS-1).
indirect enum SidebarItem {
    case tab(SidebarView.Row)
    case group(SidebarGroup)
}

/// A group as the sidebar shows it: a collapsed group that holds the selected tab is `marked`; `count` is
/// its tabs at any depth.
struct SidebarGroup {
    let name: String
    let collapsed: Bool
    let marked: Bool
    let count: Int
    let items: [SidebarItem]
}

/// What a user did to the tree in the sidebar: a row's menu, a double click or a drag. Paths are the
/// tree's (`TabPath`); a move is counted before the item is taken out (`Tree.destination`).
enum SidebarAction: Equatable {
    /// New Group… (`in` empty: the top level) or New Group Inside…, at `at` in that group.
    case newGroup(in: [Int], at: Int)
    /// New Group from Selected Tab: the tab at the path goes into a new group in its place.
    case groupTab(TabPath)
    case rename(TabPath)
    case setCollapsed(TabPath, Bool)
    case ungroup(TabPath)
    case closeGroup(TabPath)
    /// The item at `from` into the group at `into` (empty: the top level) at `at` (nil: its end).
    case move(from: TabPath, into: [Int], at: Int?)
}

/// One row of the outline. The outline view keeps items by identity: a change of the tree's shape makes
/// new nodes; a change of a tab's title, icon or loaded state only updates its node's `row` (R-11).
final class SidebarNode {
    let path: TabPath
    /// The tab's flat index, the controller's; nil for a group.
    let flat: Int?
    /// A group's row: its name, never loaded, no icon.
    var row: SidebarView.Row
    let collapsed: Bool
    let marked: Bool
    let count: Int
    let children: [SidebarNode]

    var isGroup: Bool { flat == nil }
    /// 0 at the top level.
    var level: Int { path.indexes.count - 1 }

    private init(path: TabPath, flat: Int?, row: SidebarView.Row, group: SidebarGroup? = nil,
                 children: [SidebarNode] = []) {
        self.path = path
        self.flat = flat
        self.row = row
        self.collapsed = group?.collapsed ?? false
        self.marked = group?.marked ?? false
        self.count = group?.count ?? 0
        self.children = children
    }

    /// The nodes of `items`, their tabs numbered top to bottom as the controller's flat list.
    static func nodes(_ items: [SidebarItem]) -> [SidebarNode] {
        var flat = 0
        func make(_ items: [SidebarItem], _ prefix: [Int]) -> [SidebarNode] {
            items.enumerated().map { index, item in
                let path = TabPath(prefix + [index])
                switch item {
                case .tab(let row):
                    defer { flat += 1 }
                    return SidebarNode(path: path, flat: flat, row: row)
                case .group(let group):
                    let row = SidebarView.Row(title: group.name, loaded: false, icon: nil)
                    return SidebarNode(path: path, flat: nil, row: row, group: group,
                                       children: make(group.items, path.indexes))
                }
            }
        }
        return make(items, [])
    }

    /// Every node, top to bottom, groups opened.
    static func all(_ nodes: [SidebarNode]) -> [SidebarNode] { nodes.flatMap { [$0] + all($0.children) } }

    /// Whether `old` and `new` are the same outline but for the tabs' rows: no reload needed (R-11).
    static func sameShape(_ old: [SidebarNode], _ new: [SidebarNode]) -> Bool {
        old.count == new.count && zip(old, new).allSatisfy { old, new in
            old.path == new.path && old.flat == new.flat && old.collapsed == new.collapsed
                && old.marked == new.marked && old.count == new.count
                && (!old.isGroup || old.row.title == new.row.title) && sameShape(old.children, new.children)
        }
    }
}

extension SidebarView.Row {
    /// Whether the row shows the same: title, loaded state and the same icon object.
    func same(as other: SidebarView.Row) -> Bool {
        title == other.title && loaded == other.loaded && icon === other.icon
    }
}
