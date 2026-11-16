import AppKit
import NhetrinhCore

/// The outline's data and rows (P7), and a drag: a tab into a folder, out of one, inside one, or along
/// the root; a folder along the root. A folder never goes into a folder (one level, `Tree.move`).
extension SidebarView {
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        (item as? SidebarNode)?.children.count ?? nodes.count
    }

    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        (item as? SidebarNode)?.children[index] ?? nodes[index]
    }

    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        (item as? SidebarNode)?.isFolder ?? false
    }

    func outlineView(_ outlineView: NSOutlineView, shouldSelectItem item: Any) -> Bool {
        (item as? SidebarNode)?.isFolder == false
    }

    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        guard let node = item as? SidebarNode else { return nil }
        if node.isFolder {
            let cell = outlineView.makeView(withIdentifier: FolderRowView.identifier, owner: nil) as? FolderRowView
            return (cell ?? FolderRowView()).shown(node)
        }
        let made = outlineView.makeView(withIdentifier: TabRowView.identifier, owner: nil) as? TabRowView
        let cell = made ?? TabRowView()
        cell.show(node.row)
        cell.onClose = { [weak self, weak cell] in
            guard let self, let cell else { return }
            self.closeRow(self.table.row(for: cell))
        }
        return cell
    }

    func outlineViewSelectionDidChange(_ notification: Notification) {
        guard !updating, let flat = node(atRow: table.selectedRow)?.flat else { return }
        onSelect?(flat)
    }

    func outlineViewItemDidExpand(_ notification: Notification) { folderToggled(notification, collapsed: false) }
    func outlineViewItemDidCollapse(_ notification: Notification) { folderToggled(notification, collapsed: true) }

    /// The disclosure triangle, clicked: the tree keeps the state (it is saved, P7).
    private func folderToggled(_ notification: Notification, collapsed: Bool) {
        guard !updating, let node = notification.userInfo?["NSObject"] as? SidebarNode, node.isFolder else { return }
        onAction?(.setCollapsed(folder: node.path.item, collapsed))
    }

    // MARK: - Drag

    func outlineView(_ outlineView: NSOutlineView, pasteboardWriterForItem item: Any) -> NSPasteboardWriting? {
        guard let node = item as? SidebarNode else { return nil }
        let pasteboard = NSPasteboardItem()
        pasteboard.setString("\(node.path.item),\(node.path.tab ?? -1)", forType: Self.rowType)
        return pasteboard
    }

    func outlineView(_ outlineView: NSOutlineView, validateDrop info: NSDraggingInfo, proposedItem item: Any?,
                     proposedChildIndex index: Int) -> NSDragOperation {
        guard (info.draggingSource as? NSOutlineView) === table, let from = Self.dragged(info),
              dropTarget(from, onto: item as? SidebarNode, at: index) != nil else { return [] }
        return .move
    }

    func outlineView(_ outlineView: NSOutlineView, acceptDrop info: NSDraggingInfo, item: Any?,
                     childIndex index: Int) -> Bool {
        guard let from = Self.dragged(info) else { return false }
        return drop(from, onto: item as? SidebarNode, at: index)
    }

    /// The end of a drag, as the outline proposes it: `onto` a folder's row (nil: the root), at `index`
    /// (-1: on the row itself, its end). A drop on a tab's row, or of a folder into a folder, is refused.
    @discardableResult
    func drop(_ from: TabPath, onto node: SidebarNode?, at index: Int) -> Bool {
        guard let target = dropTarget(from, onto: node, at: index) else { return false }
        onAction?(.drop(from: from, folder: target.folder, index: target.index))
        return true
    }

    private func dropTarget(_ from: TabPath, onto node: SidebarNode?, at index: Int) -> (folder: Int?, index: Int?)? {
        let place = index == NSOutlineViewDropOnItemIndex ? nil : index
        guard let node else { return (nil, place) }
        let draggingFolder = from.tab == nil && nodes.indices.contains(from.item) && nodes[from.item].isFolder
        guard node.isFolder, !draggingFolder else { return nil }
        return (node.path.item, place)
    }

    private static func dragged(_ info: NSDraggingInfo) -> TabPath? {
        guard let text = info.draggingPasteboard.pasteboardItems?.first?.string(forType: rowType) else { return nil }
        let parts = text.split(separator: ",").compactMap { Int($0) }
        guard parts.count == 2 else { return nil }
        return TabPath(item: parts[0], tab: parts[1] < 0 ? nil : parts[1])
    }
}
