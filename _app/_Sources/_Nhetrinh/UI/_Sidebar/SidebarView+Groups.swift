import AppKit
import NhetrinhCore

/// A row's menu (P7; groups since P8-GROUPS-1). A tab's: Close Tab, New Group from Selected Tab…, Move Tab to
/// Group ▸ (every group, as a path "Work > FE"), Move Out of Group. A group's: Rename Group…, Collapse /
/// Expand Group, New Group Inside…, Move Group to ▸ (Top Level, every group; one it cannot go into is
/// off, its tooltip says why), Ungroup, Close Group…. Every menu: New Group… at the top level, after the
/// row's top item; off the rows only that. The readback presses these as a user does (no drag, D18).
extension SidebarView {
    static let newGroup = "New Group…"
    static let newGroupInside = "New Group Inside…"
    static let newGroupFromTab = "New Group from Selected Tab…"
    static let moveTabToGroup = "Move Tab to Group"
    static let moveGroupTo = "Move Group to"
    static let topLevel = "Top Level"

    func menu(forRow row: Int) -> NSMenu? {
        let menu = NSMenu()
        menu.autoenablesItems = false
        guard let node = node(atRow: row) else {
            menu.addItem(actionItem(Self.newGroup) { [weak self] in
                self?.onAction?(.newGroup(in: [], at: self?.nodes.count ?? 0))
            })
            return menu
        }
        (node.isGroup ? groupItems(node) : tabItems(node)).forEach(menu.addItem)
        menu.addItem(.separator())
        let after = node.path.item + 1
        menu.addItem(actionItem(Self.newGroup) { [weak self] in self?.onAction?(.newGroup(in: [], at: after)) })
        return menu
    }

    private func groupItems(_ node: SidebarNode) -> [NSMenuItem] {
        let path = node.path
        let inside = node.children.count
        let items = [
            actionItem("Rename Group…") { [weak self] in self?.onAction?(.rename(path)) },
            actionItem(node.collapsed ? "Expand Group" : "Collapse Group") { [weak self] in
                self?.onAction?(.setCollapsed(path, !node.collapsed))
            },
            actionItem(Self.newGroupInside) { [weak self] in self?.onAction?(.newGroup(in: path.indexes, at: inside)) },
            moveMenu(Self.moveGroupTo, from: path, topLevel: true),
            actionItem("Ungroup") { [weak self] in self?.onAction?(.ungroup(path)) },
            actionItem("Close Group…") { [weak self] in self?.onAction?(.closeGroup(path)) },
        ]
        return items.compactMap { $0 }
    }

    private func tabItems(_ node: SidebarNode) -> [NSMenuItem] {
        let from = node.path
        var items = [
            actionItem("Close Tab") { [weak self] in node.flat.map { self?.onClose?($0) } },
            actionItem(Self.newGroupFromTab) { [weak self] in self?.onAction?(.groupTab(from)) },
        ]
        if let move = moveMenu(Self.moveTabToGroup, from: from, topLevel: false) { items.append(move) }
        if let group = from.parent.last {
            let out = Array(from.parent.dropLast())
            items.append(actionItem("Move Out of Group") { [weak self] in
                self?.onAction?(.move(from: from, into: out, at: group + 1))
            })
        }
        return items
    }

    /// `title` ▸ every place the item at `from` can be sent to, its own group left out; a place it cannot go
    /// is off, with the reason as its tooltip. Nil when there is no place.
    private func moveMenu(_ title: String, from: TabPath, topLevel: Bool) -> NSMenuItem? {
        let groups = SidebarNode.all(nodes).filter(\.isGroup)
        var places = groups.map { group in (title: pathTitle(group.path), path: group.path.indexes) }
        if topLevel { places.insert((Self.topLevel, []), at: 0) }
        places.removeAll { $0.path == from.parent }
        guard !places.isEmpty else { return nil }
        let move = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        let submenu = NSMenu(title: title)
        submenu.autoenablesItems = false
        for place in places {
            let item = actionItem(place.title) { [weak self] in
                self?.onAction?(.move(from: from, into: place.path, at: nil))
            }
            let refusal = moveRefusal?(from, place.path, nil)
            item.isEnabled = refusal == nil
            item.toolTip = refusal?.reason
            submenu.addItem(item)
        }
        move.submenu = submenu
        return move
    }

    /// A group's path as the menus show it: "Work > FE > PRs".
    func pathTitle(_ path: TabPath) -> String {
        path.indexes.indices.compactMap { level in
            node(at: TabPath(Array(path.indexes.prefix(level + 1))))?.row.title
        }.joined(separator: " > ")
    }

    /// The node at `path`.
    func node(at path: TabPath) -> SidebarNode? {
        var found: SidebarNode?
        var level = nodes
        for index in path.indexes {
            guard level.indices.contains(index) else { return nil }
            found = level[index]
            level = level[index].children
        }
        return found
    }
}

/// A menu item that runs a closure: the item keeps it (`representedObject`), and it is the item's target.
private final class MenuAction: NSObject {
    private let run: () -> Void

    init(_ run: @escaping () -> Void) {
        self.run = run
    }

    @objc func fire(_ sender: Any?) { run() }
}

/// A menu item that runs `run` when pressed.
private func actionItem(_ title: String, run: @escaping () -> Void) -> NSMenuItem {
    let action = MenuAction(run)
    let item = NSMenuItem(title: title, action: #selector(MenuAction.fire(_:)), keyEquivalent: "")
    item.target = action
    item.representedObject = action
    return item
}
