import AppKit
import NhetrinhCore

/// What the sidebar shows, root first: a tab, or a folder with its tabs (P7). Built by the controller.
enum SidebarItem {
    case tab(SidebarView.Row)
    case folder(name: String, collapsed: Bool, marked: Bool, tabs: [SidebarView.Row])
}

/// What a user did to the tree in the sidebar (P7): its row menu or a drag. Indexes are root indexes;
/// a drop is counted before the dragged item is taken out (`Tree.destination`).
enum SidebarAction: Equatable {
    case newFolder(at: Int)
    case rename(folder: Int)
    case setCollapsed(folder: Int, Bool)
    case delete(folder: Int)
    /// The item at `from` dropped into the folder `folder` (nil: the root) at `index` (nil: its end).
    case drop(from: TabPath, folder: Int?, index: Int?)
}

/// One row of the outline. The outline view keeps items by identity, so every update makes new nodes.
final class SidebarNode {
    let path: TabPath
    /// The tab's flat index, the controller's; nil for a folder.
    let flat: Int?
    /// A folder's row: its name, never loaded, no icon.
    let row: SidebarView.Row
    let collapsed: Bool
    let marked: Bool
    let children: [SidebarNode]

    var isFolder: Bool { flat == nil }

    private init(path: TabPath, flat: Int?, row: SidebarView.Row, folder: (collapsed: Bool, marked: Bool),
                 children: [SidebarNode] = []) {
        self.path = path
        self.flat = flat
        self.row = row
        self.collapsed = folder.collapsed
        self.marked = folder.marked
        self.children = children
    }

    /// The nodes of `items`, their tabs numbered top to bottom as the controller's flat list.
    static func nodes(_ items: [SidebarItem]) -> [SidebarNode] {
        var flat = 0
        func tab(_ row: SidebarView.Row, _ path: TabPath) -> SidebarNode {
            defer { flat += 1 }
            return SidebarNode(path: path, flat: flat, row: row, folder: (false, false))
        }
        return items.enumerated().map { index, item in
            switch item {
            case .tab(let row): return tab(row, TabPath(item: index))
            case .folder(let name, let collapsed, let marked, let rows):
                let children = rows.enumerated().map { tab($1, TabPath(item: index, tab: $0)) }
                let row = SidebarView.Row(title: name, loaded: false, icon: nil)
                return SidebarNode(path: TabPath(item: index), flat: nil, row: row, folder: (collapsed, marked),
                                   children: children)
            }
        }
    }
}
