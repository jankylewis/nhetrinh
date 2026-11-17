import AppKit

/// P8-GROUPS-1 (R-11): the outline is reloaded only when the tree's shape changes; a page's new title,
/// icon or loaded state updates its row in place.
extension SidebarView {
    /// Show `items`; `selected` is the controller's flat tab index. A tab in a collapsed group has no row
    /// to select: then no row is selected, and its group is marked. The same shape (only titles, icons or
    /// loaded states changed) updates those rows in place, without reloading the outline (R-11).
    func update(_ items: [SidebarItem], selected: Int) {
        let next = SidebarNode.nodes(items)
        updating = true
        if SidebarNode.sameShape(nodes, next) {
            refreshRows(from: next)
        } else {
            nodes = next
            reloads += 1
            table.reloadData()
            expand(nodes)
        }
        let row = tabNode(flat: selected).map { table.row(forItem: $0) } ?? -1
        if row >= 0 { table.selectRowIndexes([row], byExtendingSelection: false) } else { table.deselectAll(nil) }
        updating = false
    }

    /// Each group as the tree has it, top down: a collapsed group's groups are set when it opens.
    private func expand(_ nodes: [SidebarNode]) {
        for node in nodes where node.isGroup {
            guard !node.collapsed else {
                table.collapseItem(node)
                continue
            }
            table.expandItem(node)
            expand(node.children)
        }
    }

    /// The tabs' rows whose title, icon or loaded state changed: the node takes the new row, its view shows it.
    private func refreshRows(from next: [SidebarNode]) {
        for (old, new) in zip(SidebarNode.all(nodes), SidebarNode.all(next)) where !old.row.same(as: new.row) {
            old.row = new.row
            let row = table.row(forItem: old)
            guard row >= 0, let view = table.view(atColumn: 0, row: row, makeIfNecessary: false) as? TabRowView
            else { continue }
            view.show(old.row)
        }
    }
}
