import Foundation

/// P8-CHROME-1 (NT-BUG-018, NT-UIX-005): where the toolbar's first button starts. With the sidebar hidden
/// the toolbar reaches the window's left edge, under the close, minimize and zoom buttons (the traffic
/// lights); its first button then starts right of the zoom button's real frame, plus a gap. Every x is in
/// one space (the app reads screen points), so a sidebar shown, hidden or sliding, and full screen, where
/// the traffic lights live in another window, are the same sum.
public enum ToolbarLayout {
    /// The toolbar's own left margin, when no traffic light is over it.
    public static let margin = 8.0
    /// The space between the zoom button's right edge and the toolbar's first button.
    public static let gap = 8.0

    /// The first button's x inside the toolbar. `zoomMaxX`: the zoom button's right edge, nil when the
    /// window has none; `toolbarMinX`: the toolbar's left edge. Never left of the margin.
    public static func leading(zoomMaxX: Double?, toolbarMinX: Double) -> Double {
        guard let zoomMaxX, zoomMaxX.isFinite, toolbarMinX.isFinite else { return margin }
        return max(margin, (zoomMaxX + gap - toolbarMinX).rounded(.up))
    }
}
