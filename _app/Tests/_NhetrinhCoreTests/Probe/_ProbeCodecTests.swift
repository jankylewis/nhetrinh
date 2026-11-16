import Foundation
import Testing
@testable import NhetrinhCore

private func shown(_ rows: [String], selected: Int?) -> ProbeState {
    var state = ProbeState()
    state.title = "Example Domain"
    state.rows = rows
    state.loaded = rows.map { $0 != "A" }
    state.selected = selected
    state.address = "https://example.com/"
    state.windowShown = true
    state.sidebarWidth = 220
    state.addressShown = true
    state.shortcuts = ["File > New Tab": "⌘T", "File > Close Tab": "⌘W"]
    return state
}

@Test(arguments: [
    ProbeRequest.state,
    .navigate("example.com"),
    .navigate("rock & roll \"x\"\n"),
    .newTab,
    .closeTab,
    .select(0),
    .select(7),
    .menu(["nhetrinh", "Quit nhetrinh"]),
    .menu(["Tabs", "Back"]),
])
func requestRoundTrips(request: ProbeRequest) throws {
    let line = try ProbeCodec.encode(request)
    #expect(!line.contains("\n"))
    #expect(try ProbeCodec.decodeRequest(line) == request)
}

@Test(arguments: [
    ProbeResponse.state(shown(["A", "B"], selected: 1)),
    .state(ProbeState()),
    .done,
    .failed("no tab at index 3"),
])
func responseRoundTrips(response: ProbeResponse) throws {
    let line = try ProbeCodec.encode(response)
    #expect(!line.contains("\n"))
    #expect(try ProbeCodec.decodeResponse(line) == response)
}

@Test(arguments: ["", "{", "[]", "{\"op\":\"format-disk\"}", "{\"op\":\"select\"}", "{\"op\":\"select\",\"index\":-1}",
                  "{\"op\":\"navigate\"}", "{\"op\":\"menu\"}", "{\"op\":\"menu\",\"path\":[]}",
                  "{\"op\":\"menu\",\"path\":\"Tabs > Back\"}"])
func malformedRequestThrows(line: String) {
    #expect(throws: ProbeCodec.Failure.self) { try ProbeCodec.decodeRequest(line) }
}

@Test(arguments: ["", "{\"op\":\"state\"}", "{\"op\":\"failed\"}", "{\"op\":\"newTab\"}"])
func malformedResponseThrows(line: String) {
    #expect(throws: ProbeCodec.Failure.self) { try ProbeCodec.decodeResponse(line) }
}
