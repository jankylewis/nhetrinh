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

// P7: the folders the probe reads come back as they were sent; an older app's answer has none.
@Test(arguments: [(["work"], [["a", "b"]], [true]), ([], [], [])])
func folderFieldsRoundTrip(folders: [String], tabs: [[String]], collapsed: [Bool]) throws {
    var state = ProbeState()
    state.folders = folders
    state.folderTabs = tabs
    state.collapsedFolders = collapsed
    let line = try ProbeCodec.encode(ProbeResponse.state(state))
    #expect(try ProbeCodec.decodeResponse(line) == .state(state))
    #expect(try ProbeCodec.decodeResponse(#"{"op":"state","state":{}}"#) == .state(ProbeState()))
}
