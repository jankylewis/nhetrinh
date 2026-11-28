import AppKit

/// What the readback probe drives and reads in the sidebar (D23): a row's menu and a middle click, sent
/// to the table as the user's clicks reach it, and the icons the rows show (P2, R13, R16).
extension SidebarView {
    /// The probe's R13: a right click at the row's centre asks the table for its menu (`menu(for:)`, the
    /// path of the user's right click, with its hit test), and `item` is pressed. P7: an item of a submenu
    /// is named by its path, "Move Tab to Group > work"; an item's own title may hold " > " (P8-GROUPS-1:
    /// "Move Tab to Group > Work > FE"), the longest title that is there wins. An item that is off is not
    /// pressed, as a click on it does nothing.
    func pressRowMenu(_ row: Int, item: String) -> Bool {
        guard let click = table.rightClick(onRow: row), let menu = table.menu(for: click),
              let (owner, index) = Self.find(item.components(separatedBy: " > ")[...], in: menu),
              owner.items[index].isEnabled else { return false }
        owner.performActionForItem(at: index)
        return true
    }

    private static func find(_ parts: ArraySlice<String>, in menu: NSMenu) -> (NSMenu, Int)? {
        for length in stride(from: parts.count, to: 0, by: -1) {
            let title = parts.prefix(length).joined(separator: " > ")
            guard let index = menu.items.firstIndex(where: { $0.title == title }) else { continue }
            if length == parts.count { return (menu, index) }
            if let submenu = menu.items[index].submenu, let found = find(parts.dropFirst(length), in: submenu) {
                return found
            }
        }
        return nil
    }

    /// The probe's R13: a middle click at the row's centre (the table's hit test; the button check is unit tested).
    func middleClick(_ row: Int) -> Bool {
        guard let point = table.center(ofRow: row) else { return false }
        table.middleClick(at: point)
        return true
    }

    /// P8-FONT-1: the font family of the New Tab button, the first tab row and the first group row shown.
    var fonts: [String: String] {
        let views = (0..<table.numberOfRows).compactMap { table.view(atColumn: 0, row: $0, makeIfNecessary: false) }
        var fonts = ["New Tab": AppFont.family(of: textControls)]
        let tabRow = views.lazy.compactMap { ($0 as? TabRowView)?.textControls }.first
        let groupRow = views.lazy.compactMap { ($0 as? FolderRowView)?.textControls }.first
        fonts["sidebar row"] = tabRow.map { AppFont.family(of: $0) }
        fonts["group row"] = groupRow.map { AppFont.family(of: $0) }
        return fonts
    }

    /// Per row: whether its view shows the site's icon, not the globe (read by the probe, R16).
    var shownIcons: [Bool] {
        (0..<table.numberOfRows).map { row in
            (table.view(atColumn: 0, row: row, makeIfNecessary: false) as? TabRowView)?.showsSiteIcon ?? false
        }
    }
}
