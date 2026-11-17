import NhetrinhCore
import Testing
@testable import NhetrinhReadback

// P8-CHROME-1, R48: what the step says is wrong with the toolbar's left buttons against the traffic lights.
// A button or the zoom button the probe did not read is named: never taken as clear. Red first.

private func state(_ frames: [String: [Double]], zoom: Double? = 66) -> ProbeState {
    var state = ProbeState()
    state.toolbarFrames = frames
    state.zoomMaxX = zoom
    return state
}

private let clear: [String: [Double]] = ["Toggle Sidebar": [74, 6, 28, 28], "Back": [108, 6, 28, 28]]

@Test(arguments: [
    (state(clear), []),
    (state(clear.merging(["Toggle Sidebar": [8, 6, 28, 28]]) { $1 }),
     ["Toggle Sidebar starts at x 8, left of the zoom button's right edge 66"]),
    (state(["Toggle Sidebar": [8, 6, 28, 28], "Back": [42, 6, 28, 28]]),
     ["Toggle Sidebar starts at x 8, left of the zoom button's right edge 66",
      "Back starts at x 42, left of the zoom button's right edge 66"]),
    (state(clear.merging(["Back": [90, 6, 28, 28]]) { $1 }),
     ["Back starts at x 90, left of Toggle Sidebar's right edge 102"]),
    (state(["Back": [108, 6, 28, 28]]), ["Toggle Sidebar: not read"]),
    (state(clear.merging(["Back": [108, 6]]) { $1 }), ["Back: not read"]),
    (state(clear, zoom: nil), ["the zoom button: not read"]),
] as [(ProbeState, [String])])
func toggleStepNamesEveryButtonOverTheTrafficLights(state: ProbeState, wrong: [String]) {
    #expect(ToggleStep.wrong(state) == wrong)
}

@Test func toggleStepReadsTheToggleThenBack() {
    #expect(ToggleStep.buttons == ["Toggle Sidebar", "Back"])
    #expect(ToggleStep.step.id == "R48")
}
