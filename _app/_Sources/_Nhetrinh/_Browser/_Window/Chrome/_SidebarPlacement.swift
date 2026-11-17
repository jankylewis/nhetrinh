import AppKit
import NhetrinhCore

/// P8-SIDE-1 (headmate request): the tab sidebar on the left or the right of the window (Settings Hub >
/// Sidebar position, `prefs.sidebarSide`), applied at once. The sidebar's split view item moves to that end
/// with its width and its shown or hidden state; the web view takes the rest, so the two never overlap. The
/// traffic lights stay top left: the toolbar's row clears them from their real frame (P8-CHROME-1).
extension BrowserWindowController {
    /// The sidebar's split view item, on either side.
    var sideItem: NSSplitViewItem? { split.splitViewItems.first { $0.viewController.view === sidebar } }

    /// A sidebar item for `controller`: the same bounds and collapse on both sides.
    static func makeSideItem(_ controller: NSViewController) -> NSSplitViewItem {
        let item = NSSplitViewItem(sidebarWithViewController: controller)
        item.minimumThickness = 180
        item.maximumThickness = 420
        item.canCollapse = true
        return item
    }

    /// Put the sidebar on `side`; the toolbar's toggle shows that side (`sidebar.left`, `sidebar.right`).
    func placeSidebar(_ side: SidebarSide) {
        toolbar.showSide(side)
        guard let item = sideItem, let index = split.splitViewItems.firstIndex(of: item) else { return }
        let end = side == .left ? 0 : split.splitViewItems.count - 1
        guard index != end else { return }
        let collapsed = item.isCollapsed
        if !collapsed, sidebar.frame.width >= 100 { sidebarWidth = Double(sidebar.frame.width) }
        split.removeSplitViewItem(item)
        let moved = Self.makeSideItem(item.viewController)
        moved.isCollapsed = collapsed
        split.insertSplitViewItem(moved, at: end)
        if !collapsed { keepSidebarWidth(sidebarWidth) }
        sessionChanged()
    }

    /// The divider set so the sidebar is `width` wide on its side (a restore, a move to the other side).
    func keepSidebarWidth(_ width: Double) {
        let view = split.splitView
        view.layoutSubtreeIfNeeded()
        let position = SidebarLayout.divider(prefs.sidebarSide, sidebarWidth: width, width: Double(view.bounds.width),
                                             thickness: Double(view.dividerThickness))
        view.setPosition(CGFloat(position), ofDividerAt: 0)
    }

    /// The probe (R50): the side, the toggle's symbol, the sidebar's frame ([] when hidden) and the web view's,
    /// in the window's points.
    func readSide(into state: inout ProbeState) {
        state.sidebarSide = prefs.sidebarSide.rawValue
        state.toggleSymbol = toolbar.toggleSymbol
        state.sidebarFrame = state.sidebarWidth > 0 ? Self.frame(of: sidebar) : []
        state.webFrame = Self.frame(of: webContainer)
    }

    private static func frame(of view: NSView) -> [Double] {
        guard view.window != nil else { return [] }
        let frame = view.convert(view.bounds, to: nil)
        return [frame.minX, frame.minY, frame.width, frame.height].map(Double.init)
    }
}
