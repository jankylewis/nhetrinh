import AppKit

/// The sidebar's outline (P7; a table before): a middle click on a row closes it, and the row a menu
/// was shown on is kept, so the menu acts on that row and not on the selected one (P2). Each row has
/// its own menu: a tab's, or a group's; off the rows, the sidebar's own (`menuForRow` with -1, P8-GROUPS-1).
final class TabTable: NSOutlineView {
    var onMiddleClick: ((Int) -> Void)?
    var menuForRow: ((Int) -> NSMenu?)?
    /// The row the last menu was shown on; -1 when it was shown on no row.
    private(set) var menuRow = -1

    /// A right click (or ⌃-click) on a row: its menu. Off the rows: the sidebar's menu (New Group…).
    override func menu(for event: NSEvent) -> NSMenu? {
        menuRow = row(at: convert(event.locationInWindow, from: nil))
        return menuForRow?(menuRow)
    }

    override func otherMouseDown(with event: NSEvent) {
        guard event.buttonNumber == 2 else { return super.otherMouseDown(with: event) }
    }

    override func otherMouseUp(with event: NSEvent) {
        guard event.buttonNumber == 2 else { return super.otherMouseUp(with: event) }
        middleClick(at: event.locationInWindow)
    }

    /// A middle click at `point`, in window coordinates: the row under it closes; off the rows, nothing.
    func middleClick(at point: NSPoint) {
        let row = self.row(at: convert(point, from: nil))
        if row >= 0 { onMiddleClick?(row) }
    }

    /// The centre of `row` in window coordinates, where a click on the row lands; nil off the rows.
    func center(ofRow row: Int) -> NSPoint? {
        guard row >= 0, row < numberOfRows, window != nil else { return nil }
        let frame = rect(ofRow: row)
        return convert(NSPoint(x: frame.midX, y: frame.midY), to: nil)
    }

    /// The right mouse down a click at the centre of `row` sends (the readback probe, R13; an event of
    /// this app only, no system event, D18). Nil off the rows or with no window.
    func rightClick(onRow row: Int) -> NSEvent? {
        guard let point = center(ofRow: row), let window else { return nil }
        return NSEvent.mouseEvent(with: .rightMouseDown, location: point, modifierFlags: [],
                                  timestamp: ProcessInfo.processInfo.systemUptime, windowNumber: window.windowNumber,
                                  context: nil, eventNumber: 0, clickCount: 1, pressure: 1)
    }
}
