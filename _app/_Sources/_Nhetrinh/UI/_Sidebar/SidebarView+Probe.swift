import AppKit

/// What the readback probe drives and reads in the sidebar (D23): a row's menu and a middle click, sent
/// to the table as the user's clicks reach it, and the icons the rows show (P2, R13, R16).
extension SidebarView {
    /// The probe's R13: a right click at the row's centre asks the table for its menu (`menu(for:)`, the
    /// path of the user's right click, with its hit test), and `item` is pressed.
    func pressRowMenu(_ row: Int, item: String) -> Bool {
        guard let click = table.rightClick(onRow: row), let menu = table.menu(for: click),
              let index = menu.items.firstIndex(where: { $0.title == item }) else { return false }
        menu.performActionForItem(at: index)
        return true
    }

    /// The probe's R13: a middle click at the row's centre (the table's hit test; the button check is unit tested).
    func middleClick(_ row: Int) -> Bool {
        guard let point = table.center(ofRow: row) else { return false }
        table.middleClick(at: point)
        return true
    }

    /// Per row: whether its view shows the site's icon, not the globe (read by the probe, R16).
    var shownIcons: [Bool] {
        (0..<table.numberOfRows).map { row in
            (table.view(atColumn: 0, row: row, makeIfNecessary: false) as? TabRowView)?.showsSiteIcon ?? false
        }
    }
}
