import AppKit

/// The sidebar's table: a middle click on a row closes it, and the row a menu was shown on is kept,
/// so the menu's Close Tab closes that row and not the selected one (P2).
final class TabTable: NSTableView {
    var onMiddleClick: ((Int) -> Void)?
    /// The row the last menu was shown on; -1 when it was shown on no row.
    private(set) var menuRow = -1

    override func menu(for event: NSEvent) -> NSMenu? {
        let row = self.row(at: convert(event.locationInWindow, from: nil))
        return row >= 0 ? menu(forRow: row) : nil
    }

    /// The menu of `row`, as a right click on it gives it.
    func menu(forRow row: Int) -> NSMenu? {
        menuRow = row
        return menu
    }

    override func otherMouseDown(with event: NSEvent) {
        guard event.buttonNumber == 2 else { return super.otherMouseDown(with: event) }
    }

    override func otherMouseUp(with event: NSEvent) {
        guard event.buttonNumber == 2 else { return super.otherMouseUp(with: event) }
        let row = self.row(at: convert(event.locationInWindow, from: nil))
        if row >= 0 { onMiddleClick?(row) }
    }
}
