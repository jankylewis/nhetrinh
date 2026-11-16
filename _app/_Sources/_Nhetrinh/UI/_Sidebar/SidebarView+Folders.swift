import AppKit
import NhetrinhCore

/// A row's menu (P7). A tab's: Close Tab, Move to Folder (each other folder), Move Out of Folder. A
/// folder's: Rename Folder…, Collapse / Expand Folder, Delete Folder (its tabs stay, at the root). Both:
/// New Folder…, after the row's root item. The readback presses these as a user does (no drag, D18).
extension SidebarView {
    static let newFolder = "New Folder…"
    static let moveToFolder = "Move to Folder"

    func menu(forRow row: Int) -> NSMenu? {
        guard let node = node(atRow: row) else { return nil }
        let menu = NSMenu()
        if node.isFolder {
            let folder = node.path.item
            menu.addItem(actionItem("Rename Folder…") { [weak self] in self?.onAction?(.rename(folder: folder)) })
            menu.addItem(actionItem(node.collapsed ? "Expand Folder" : "Collapse Folder") { [weak self] in
                self?.onAction?(.setCollapsed(folder: folder, !node.collapsed))
            })
            menu.addItem(actionItem("Delete Folder") { [weak self] in self?.onAction?(.delete(folder: folder)) })
        } else {
            tabItems(node).forEach(menu.addItem)
        }
        menu.addItem(.separator())
        let after = node.path.item + 1
        menu.addItem(actionItem(Self.newFolder) { [weak self] in self?.onAction?(.newFolder(at: after)) })
        return menu
    }

    private func tabItems(_ node: SidebarNode) -> [NSMenuItem] {
        var items: [NSMenuItem] = [actionItem("Close Tab") { [weak self] in node.flat.map { self?.onClose?($0) } }]
        let from = node.path
        let folders = nodes.filter { $0.isFolder && $0.path.item != (from.tab == nil ? -1 : from.item) }
        if !folders.isEmpty {
            let move = NSMenuItem(title: Self.moveToFolder, action: nil, keyEquivalent: "")
            move.submenu = NSMenu(title: Self.moveToFolder)
            for folder in folders {
                move.submenu?.addItem(actionItem(folder.row.title) { [weak self] in
                    self?.onAction?(.drop(from: from, folder: folder.path.item, index: nil))
                })
            }
            items.append(move)
        }
        if from.tab != nil {
            items.append(actionItem("Move Out of Folder") { [weak self] in
                self?.onAction?(.drop(from: from, folder: nil, index: from.item + 1))
            })
        }
        return items
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
