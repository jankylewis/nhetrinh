import Foundation
import Testing
@testable import NhetrinhCore

// P6 and P7 probe additions. P6: the readback-only "simulate pressure" request (NHT_READBACK=1 only;
// never real system pressure).

@Test(arguments: [UnloadPolicy.Pressure.normal, .warning, .critical])
func pressureRequestRoundTrips(level: UnloadPolicy.Pressure) throws {
    let line = try ProbeCodec.encode(ProbeRequest.pressure(level))
    #expect(try ProbeCodec.decodeRequest(line) == .pressure(level))
    #expect(line.contains("\"op\":\"pressure\"") && line.contains("\"text\":\"\(level.rawValue)\""))
}

/// An unknown or missing level is malformed: the app never guesses a level.
@Test(arguments: [#"{"op":"pressure","text":"severe"}"#, #"{"op":"pressure"}"#, #"{"op":"pressure","text":""}"#])
func aPressureRequestWithoutAKnownLevelIsMalformed(line: String) {
    #expect(throws: ProbeCodec.Failure.self) { try ProbeCodec.decodeRequest(line) }
}

// P7: the folders the probe reads come back as they were sent; an older app's answer has none. P8-GROUPS-1:
// the group fields too.
@Test(arguments: [(["work"], [["a", "b"]], [true]), ([], [], [])])
func folderFieldsRoundTrip(folders: [String], tabs: [[String]], collapsed: [Bool]) throws {
    var state = ProbeState()
    state.folders = folders
    state.folderTabs = tabs
    state.collapsedFolders = collapsed
    state.groupPaths = folders.map { "MBing > \($0)" }
    state.groupCounts = folders.map { _ in 2 }
    state.rowLevels = folders.map { _ in 3 }
    state.tabTitles = tabs.flatMap { $0 }
    state.groupRefusal = folders.isEmpty ? "" : TreeFailure.tooDeep.reason
    let line = try ProbeCodec.encode(ProbeResponse.state(state))
    #expect(try ProbeCodec.decodeResponse(line) == .state(state))
    #expect(try ProbeCodec.decodeResponse(#"{"op":"state","state":{}}"#) == .state(ProbeState()))
}

// P8-MIN-1: the window request and the minimized state come back as they were sent.
@Test(arguments: ["Minimize", "Restore"])
func windowRequestRoundTrips(item: String) throws {
    let line = try ProbeCodec.encode(ProbeRequest.window(item))
    #expect(try ProbeCodec.decodeRequest(line) == .window(item))
    #expect(line.contains("\"op\":\"window\""))
}

@Test(arguments: [#"{"op":"window"}"#, #"{"op":"window","text":""}"#])
func aWindowRequestWithoutAnItemIsMalformed(line: String) {
    #expect(throws: ProbeCodec.Failure.self) { try ProbeCodec.decodeRequest(line) }
}

@Test(arguments: [true, false])
func minimizedRoundTrips(minimized: Bool) throws {
    var state = ProbeState()
    state.minimized = minimized
    #expect(try ProbeCodec.decodeResponse(ProbeCodec.encode(ProbeResponse.state(state))) == .state(state))
}

// P8-FONT-1: the font family per control comes back as it was sent; an older app's answer has none.
@Test(arguments: [[:], ["address bar": "Menlo", "find bar": "mixed: Menlo, Helvetica"]])
func fontsRoundTrip(fonts: [String: String]) throws {
    var state = ProbeState()
    state.fonts = fonts
    #expect(try ProbeCodec.decodeResponse(ProbeCodec.encode(ProbeResponse.state(state))) == .state(state))
    #expect(try ProbeCodec.decodeResponse(#"{"op":"state","state":{}}"#) == .state(ProbeState()))
}

// P8-CHROME-1: the toolbar's left buttons' frames and the zoom button's right edge come back as sent;
// an older app's answer has none (no zoom button read: nil, never 0).
@Test(arguments: [([:], nil), (["Toggle Sidebar": [74, 6, 28, 28], "Back": [108, 6, 28, 28]], 66.0)]
      as [([String: [Double]], Double?)])
func toolbarFramesRoundTrip(frames: [String: [Double]], zoomMaxX: Double?) throws {
    var state = ProbeState()
    state.toolbarFrames = frames
    state.zoomMaxX = zoomMaxX
    #expect(try ProbeCodec.decodeResponse(ProbeCodec.encode(ProbeResponse.state(state))) == .state(state))
    #expect(try ProbeCodec.decodeResponse(#"{"op":"state","state":{}}"#) == .state(ProbeState()))
}

// P8-SIDE-1: the sidebar's side and the sidebar's and the web view's frames come back as sent; an older
// app's answer has none ("" and empty: never taken as Left, never as no overlap).
@Test(arguments: [("", [], []), ("right", [780.0, 0, 220, 800], [0.0, 0, 779, 760])] as [(String, [Double], [Double])])
func sidebarSideAndFramesRoundTrip(side: String, sidebar: [Double], web: [Double]) throws {
    var state = ProbeState()
    state.sidebarSide = side
    state.toggleSymbol = side.isEmpty ? "" : "sidebar." + side
    state.sidebarFrame = sidebar
    state.webFrame = web
    #expect(try ProbeCodec.decodeResponse(ProbeCodec.encode(ProbeResponse.state(state))) == .state(state))
    #expect(try ProbeCodec.decodeResponse(#"{"op":"state","state":{}}"#) == .state(ProbeState()))
}
