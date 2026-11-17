import Foundation
import Testing
@testable import NhetrinhCore

// P8-SIDE-1 (headmate request): the tab sidebar on the left or the right of the window. Red first.

/// No key, a value of another kind or an unknown side: Left. A known side is read; every other key stays.
@Test(arguments: [
    (nil, SidebarSide.left), (#""right""#, .right), (#""left""#, .left), (#""Right""#, .left), (#""top""#, .left),
    ("1", .left), ("true", .left), ("null", .left), (#"["right"]"#, .left), (#"{"side": "right"}"#, .left),
] as [(String?, SidebarSide)])
func theSidebarSideIsLeftUnlessRightIsSaved(value: String?, side: SidebarSide) throws {
    let json = #"{"searchEngine": "bing""# + (value.map { #", "sidebarSide": "# + $0 } ?? "") + "}"
    let prefs = try #require(Prefs.decode(Data(json.utf8)))
    #expect(prefs.sidebarSide == side && prefs.searchEngine == .bing)
}

@Test func theDefaultSideIsLeftAndASavedSideComesBack() throws {
    #expect(Prefs().sidebarSide == .left)
    var prefs = Prefs()
    prefs.sidebarSide = .right
    #expect(try Prefs.decode(prefs.encoded()) == prefs)
    #expect(SidebarSide.allCases.map(\.title) == ["Left", "Right"])
    #expect(SidebarSide.allCases.map(\.symbol) == ["sidebar.left", "sidebar.right"])
}

/// A window 1000 wide, a sidebar 220 wide, a divider 1 thick: where the toolbar (and the web view) start,
/// where the sidebar starts (nil: hidden), and whether the sidebar sits under the traffic lights.
@Test(arguments: [
    (SidebarSide.left, true, 221.0, 0.0 as Double?, true),
    (.left, false, 0, nil, false),
    (.right, true, 0, 780, false),
    (.right, false, 0, nil, false),
] as [(SidebarSide, Bool, Double, Double?, Bool)])
func theToolbarAndTheSidebarStartWhereTheSideSays(side: SidebarSide, shown: Bool, toolbarX: Double,
                                                  sidebarX: Double?, underLights: Bool) {
    let place = SidebarLayout.place(side, shown: shown, width: 1000, sidebarWidth: 220, divider: 1)
    #expect(place == SidebarLayout.Place(toolbarX: toolbarX, sidebarX: sidebarX))
    #expect(SidebarLayout.underLights(side, shown: shown) == underLights)
}

/// The first button always starts right of the zoom button (66); only a sidebar under the lights needs no inset.
@Test(arguments: [(SidebarSide.left, true, 8.0), (.left, false, 74), (.right, true, 74), (.right, false, 74)])
func theToolbarClearsTheTrafficLightsOnBothSides(side: SidebarSide, shown: Bool, leading: Double) {
    let place = SidebarLayout.place(side, shown: shown, width: 1000, sidebarWidth: 220, divider: 1)
    #expect(ToolbarLayout.leading(zoomMaxX: 66, toolbarMinX: place.toolbarX) == leading)
    #expect(place.toolbarX + leading >= 66 + ToolbarLayout.gap)
    #expect((leading == ToolbarLayout.margin) == SidebarLayout.underLights(side, shown: shown))
}

/// The split view's divider for a kept sidebar width: its right edge on the left, its left edge on the right.
@Test(arguments: [(SidebarSide.left, 220.0, 220.0), (.left, 300, 300), (.right, 220, 779), (.right, 300, 699)])
func theDividerKeepsTheSidebarWidth(side: SidebarSide, sidebarWidth: Double, position: Double) {
    #expect(SidebarLayout.divider(side, sidebarWidth: sidebarWidth, width: 1000, thickness: 1) == position)
}

/// The sidebar and the web view as [x, y, width, height]: they overlap only when their x ranges do.
@Test(arguments: [
    ([780.0, 0, 220, 800], [0.0, 0, 779, 760], false), ([0, 0, 220, 800], [221, 0, 779, 760], false),
    ([780, 0, 220, 800], [0, 0, 781, 760], true), ([0, 0, 220, 800], [219, 0, 781, 760], true),
    ([780, 0, 220, 800], [0, 0, 780, 760], false), ([0, 0, 220], [221, 0, 779, 760], true),
] as [([Double], [Double], Bool)])
func aSidebarAndAWebViewOverlapWhenTheirXRangesDo(sidebar: [Double], web: [Double], overlap: Bool) {
    #expect(SidebarLayout.overlap(sidebar, web) == overlap)
}
