import AppKit
import NhetrinhCore

/// P8-CHROME-1 (NT-BUG-018, NT-UIX-005): the toolbar and the window's traffic lights. The zoom button's
/// frame is read from the real button (`standardWindowButton(.zoomButton)`), never guessed.
extension ToolbarView {
    /// A symbol button by its label ("Back", "Toggle Sidebar").
    func button(_ label: String) -> NSButton? { buttons.first { $0.accessibilityLabel() == label } }

    /// The zoom button's right edge in this window's points; nil when the window has none.
    var zoomMaxX: Double? {
        guard let window, let screen = Self.zoomOnScreen(of: window) else { return nil }
        return Double(window.convertFromScreen(screen).maxX)
    }

    /// The probe (R48): the toggle and Back buttons as [x, y, width, height] in the window's points.
    var buttonFrames: [String: [Double]] {
        var frames: [String: [Double]] = [:]
        for label in ["Toggle Sidebar", "Back"] {
            guard let button = button(label), button.window != nil else { continue }
            let frame = button.convert(button.bounds, to: nil)
            frames[label] = [frame.minX, frame.minY, frame.width, frame.height].map(Double.init)
        }
        return frames
    }

    /// The row's left edge from the real zoom button and this toolbar, both on the screen (`ToolbarLayout`).
    /// Called on every layout: a sidebar shown, hidden or sliding, a resize and full screen all lay it out.
    func placeRow() {
        guard let rowLeading else { return }
        var leading = ToolbarLayout.margin
        if let window, let zoom = Self.zoomOnScreen(of: window) {
            let minX = window.convertToScreen(convert(bounds, to: nil)).minX
            leading = ToolbarLayout.leading(zoomMaxX: Double(zoom.maxX), toolbarMinX: Double(minX))
        }
        if rowLeading.constant != CGFloat(leading) { rowLeading.constant = CGFloat(leading) }
    }

    /// P8-SIDE-1: the toggle drawn with the sidebar on `side`. The row is laid out again by the split view.
    func showSide(_ side: SidebarSide) {
        guard toggleSymbol != side.symbol, let toggle = button("Toggle Sidebar") else { return }
        toggle.image = NSImage(systemSymbolName: side.symbol, accessibilityDescription: "Toggle Sidebar")
        toggleSymbol = side.symbol
    }

    /// Full screen moves the traffic lights to the title bar's own window: lay out again once it is done.
    func watchFullScreen() {
        let center = NotificationCenter.default
        for name in [NSWindow.didEnterFullScreenNotification, NSWindow.didExitFullScreenNotification] {
            center.removeObserver(self, name: name, object: nil)
            if let window { center.addObserver(self, selector: #selector(layOutAgain), name: name, object: window) }
        }
    }

    @objc private func layOutAgain(_ note: Notification) { needsLayout = true }

    /// The zoom button on the screen. In full screen it lives in the title bar's own window: the screen is
    /// the one space both share.
    static func zoomOnScreen(of window: NSWindow) -> NSRect? {
        guard let zoom = window.standardWindowButton(.zoomButton), let home = zoom.window else { return nil }
        return home.convertToScreen(zoom.convert(zoom.bounds, to: nil))
    }
}
