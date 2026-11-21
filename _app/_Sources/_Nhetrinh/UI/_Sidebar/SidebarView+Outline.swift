import AppKit
import NhetrinhCore

/// The outline's data and rows (P7), and a drag: a tab or a group (with all inside) into a group, out of
/// one, inside one, or along the top level (P8-GROUPS-1). The tree says what is refused (`moveRefusal`):
/// a group into itself or past `GroupDepth.max` levels.
extension SidebarView {
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        (item as? SidebarNode)?.children.count ?? nodes.count
    }

    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        (item as? SidebarNode)?.children[index] ?? nodes[index]
    }

    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        (item as? SidebarNode)?.isGroup ?? false
    }

    func outlineView(_ outlineView: NSOutlineView, shouldSelectItem item: Any) -> Bool {
        (item as? SidebarNode)?.isGroup == false
    }

    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        guard let node = item as? SidebarNode else { return nil }
        if node.isGroup {
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
        guard !updating, let node = notification.userInfo?["NSObject"] as? SidebarNode, node.isGroup else { return }
        onAction?(.setCollapsed(node.path, collapsed))
    }

    /// The outline's click: on the disclosure arrow the outline itself opens or closes the group.
    @objc func clicked() {
        let row = table.clickedRow
        guard row >= 0, let event = NSApp.currentEvent else { return }
        let point = table.convert(event.locationInWindow, from: nil)
        if !table.frameOfOutlineCell(atRow: row).contains(point) { click(row: row) }
    }

    /// One click on a group's row, anywhere on it: opens or closes it, as Expand / Collapse Group does
    /// (NT-FEAT-063): the tree keeps the state, and the outline follows it.
    func click(row: Int) {
        guard let node = node(atRow: row), node.isGroup else { return }
        onAction?(.setCollapsed(node.path, !node.collapsed))
    }

    // MARK: - Drag

    func outlineView(_ outlineView: NSOutlineView, pasteboardWriterForItem item: Any) -> NSPasteboardWriting? {
        guard let node = item as? SidebarNode else { return nil }
        let pasteboard = NSPasteboardItem()
        pasteboard.setString(node.path.indexes.map(String.init).joined(separator: "."), forType: Self.rowType)
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

    /// The end of a drag, as the outline proposes it: `onto` a group's row (nil: the top level), at `index`
    /// (-1: on the row itself, its end). A drop on a tab's row, or one the tree refuses, is refused.
    @discardableResult
    func drop(_ from: TabPath, onto node: SidebarNode?, at index: Int) -> Bool {
        guard let target = dropTarget(from, onto: node, at: index) else { return false }
        onAction?(.move(from: from, into: target.into, at: target.at))
        return true
    }

    private func dropTarget(_ from: TabPath, onto node: SidebarNode?, at index: Int) -> (into: [Int], at: Int?)? {
        let place = index == NSOutlineViewDropOnItemIndex ? nil : index
        guard node?.isGroup ?? true else { return nil }
        let into = node?.path.indexes ?? []
        return moveRefusal?(from, into, place) == nil ? (into, place) : nil
    }

    private static func dragged(_ info: NSDraggingInfo) -> TabPath? {
        guard let text = info.draggingPasteboard.pasteboardItems?.first?.string(forType: rowType) else { return nil }
        let indexes = text.split(separator: ".").compactMap { Int($0) }
        return indexes.isEmpty ? nil : TabPath(indexes)
    }
}
