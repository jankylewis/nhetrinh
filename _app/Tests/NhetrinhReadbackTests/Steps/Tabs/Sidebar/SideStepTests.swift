import NhetrinhCore
import Testing
@testable import NhetrinhReadback

// P8-SIDE-1, R50: what the step says is wrong with the sidebar's side, its frame against the web view's, and the
// toolbar against the traffic lights. A frame or a side the probe did not read is named: never taken as right.

private func state(_ side: String, sidebar: [Double], web: [Double] = [0, 0, 779, 760],
                   toggle: [Double] = [74, 6, 28, 28]) -> ProbeState {
    var state = ProbeState()
    state.sidebarSide = side
    state.toggleSymbol = side.isEmpty ? "" : "sidebar." + side
    state.sidebarFrame = sidebar
    state.webFrame = web
    state.zoomMaxX = 66
    state.toolbarFrames = ["Toggle Sidebar": toggle, "Back": [toggle[0] + 34, 6, 28, 28]]
    return state
}

private let right = [780.0, 0, 220, 800]
private let left = [0.0, 0, 220, 800]
private let webRightOfLeft = [221.0, 0, 779, 760]

@Test(arguments: [
    (state("right", sidebar: right), SidebarSide.right, true, []),
    (state("right", sidebar: []), .right, false, []),
    (state("left", sidebar: left, web: webRightOfLeft, toggle: [229, 6, 28, 28]), .left, true, []),
    (state("left", sidebar: []), .left, false, []),
    (state("left", sidebar: left, web: webRightOfLeft, toggle: [229, 6, 28, 28]), .right, true,
     ["the side reads \"left\"", "the toggle shows \"sidebar.left\"",
      "the sidebar (x 0 to 220) is not right of the web view (x 221 to 1000)"]),
    (state("right", sidebar: right, web: [0, 0, 800, 760]), .right, true,
     ["the sidebar (x 780 to 1000) overlaps the web view (x 0 to 800)"]),
    (state("right", sidebar: right, toggle: [8, 6, 28, 28]), .right, true,
     ["Toggle Sidebar starts at x 8, left of the zoom button's right edge 66",
      "Back starts at x 42, left of the zoom button's right edge 66"]),
    (state("right", sidebar: right), .right, false, ["hidden, yet the sidebar reads [780.0, 0.0, 220.0, 800.0]"]),
    (state("right", sidebar: []), .right, true, ["the sidebar's or the web view's frame: not read"]),
    (state("right", sidebar: right, web: []), .right, true, ["the sidebar's or the web view's frame: not read"]),
    (state("", sidebar: left, web: webRightOfLeft, toggle: [229, 6, 28, 28]), .left, true,
     ["the side reads \"\"", "the toggle shows \"\""]),
] as [(ProbeState, SidebarSide, Bool, [String])])
func sideStepNamesWhatIsWrong(state: ProbeState, side: SidebarSide, shown: Bool, wrong: [String]) {
    #expect(SideStep.wrong(state, side: side, shown: shown) == wrong)
}

@Test func sideStepIsR50OnTheHubsOwnControl() {
    #expect(SideStep.step.id == "R50")
    #expect(SideStep.control == "Sidebar position")
}
