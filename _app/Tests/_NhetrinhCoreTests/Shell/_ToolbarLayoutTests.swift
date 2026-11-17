import Foundation
import Testing
@testable import NhetrinhCore

// P8-CHROME-1 (NT-BUG-018): with the sidebar hidden, the toolbar's buttons sat under the traffic lights:
// the row started 8 points from the toolbar's edge, whatever covered it. Red first.

/// The zoom button of a standard window ends near x 66 (read from the real button in the app; never
/// assumed by the code). Toolbar x 0: the sidebar hidden; 241: shown (220 wide); 30: sliding shut.
@Test(arguments: [
    (66.0, 0.0, 74.0),      // sidebar hidden: right of the zoom button, plus the gap
    (66.0, 241.0, 8.0),     // sidebar shown: the traffic lights are over the sidebar; the margin
    (66.0, 30.0, 44.0),     // sidebar sliding shut: still clear of the zoom button
    (66.5, 0.0, 75.0),      // a part of a point: rounded up, never under the button
    (1066.0, 1000.0, 74.0), // a window away from the screen's edge: only the difference counts
    (-934.0, -1000.0, 74.0), // a screen left of the main one: negative x
])
func theFirstButtonStartsRightOfTheZoomButton(zoomMaxX: Double, toolbarMinX: Double, leading: Double) {
    #expect(ToolbarLayout.leading(zoomMaxX: zoomMaxX, toolbarMinX: toolbarMinX) == leading)
}

/// No traffic lights read (no window yet), or a value that is not a number: the margin, never a guess.
@Test(arguments: [(nil, 0.0), (Double.nan, 0.0), (66.0, Double.infinity)] as [(Double?, Double)])
func withoutAZoomButtonTheMarginStays(zoomMaxX: Double?, toolbarMinX: Double) {
    #expect(ToolbarLayout.leading(zoomMaxX: zoomMaxX, toolbarMinX: toolbarMinX) == ToolbarLayout.margin)
}

/// Wherever the toolbar starts, its first button starts at least a gap right of the zoom button.
@Test(arguments: [-50.0, 0.0, 12.0, 58.0, 66.0, 100.0, 241.0])
func theGapIsAlwaysKept(toolbarMinX: Double) {
    let start = toolbarMinX + ToolbarLayout.leading(zoomMaxX: 66, toolbarMinX: toolbarMinX)
    #expect(start >= 66 + ToolbarLayout.gap)
}
