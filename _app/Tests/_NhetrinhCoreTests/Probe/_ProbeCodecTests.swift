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
    state.icons = rows.map { $0 == "B" }
    state.loading = true
    state.progressShown = true
    state.reloadButton = "Stop"
    state.webMenu = ["Open Link in New Tab", "Copy Link"]
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
    .rowMenu(row: 2, item: "Close Tab"),
    .linkMenu(item: "Open Link in New Tab"),
    .button("Stop"),
    .middleClick(row: 0),
    .middleClick(row: 3),
    .commandClickLink,
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
                  "{\"op\":\"menu\",\"path\":\"Tabs > Back\"}", "{\"op\":\"rowMenu\",\"text\":\"Close Tab\"}",
                  "{\"op\":\"rowMenu\",\"index\":-1,\"text\":\"Close Tab\"}", "{\"op\":\"rowMenu\",\"index\":0}",
                  "{\"op\":\"linkMenu\"}", "{\"op\":\"button\"}", "{\"op\":\"button\",\"text\":\"\"}",
                  "{\"op\":\"middleClick\"}", "{\"op\":\"middleClick\",\"index\":-1}"])
func malformedRequestThrows(line: String) {
    #expect(throws: ProbeCodec.Failure.self) { try ProbeCodec.decodeRequest(line) }
}

@Test(arguments: ["", "{\"op\":\"state\"}", "{\"op\":\"failed\"}", "{\"op\":\"newTab\"}"])
func malformedResponseThrows(line: String) {
    #expect(throws: ProbeCodec.Failure.self) { try ProbeCodec.decodeResponse(line) }
}
