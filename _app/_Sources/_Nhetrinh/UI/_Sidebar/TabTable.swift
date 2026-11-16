import AppKit

/// The sidebar's table: a middle click on a row closes it, and the row a menu was shown on is kept,
/// so the menu's Close Tab closes that row and not the selected one (P2).
final class TabTable: NSTableView {
    var onMiddleClick: ((Int) -> Void)?
    /// The row the last menu was shown on; -1 when it was shown on no row.
    private(set) var menuRow = -1

    /// A right click (or ⌃-click) on a row: its menu. Off the rows: no menu.
    override func menu(for event: NSEvent) -> NSMenu? {
        menuRow = row(at: convert(event.locationInWindow, from: nil))
        return menuRow >= 0 ? menu : nil
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
