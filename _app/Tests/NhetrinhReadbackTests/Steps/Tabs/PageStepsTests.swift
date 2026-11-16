import NhetrinhCore
import Testing
@testable import NhetrinhReadback

// R17's ⌘-click part (ruling READBACK P2-2): the link's menu is the readback; a ⌘-click that does not
// reach the page is said in the line as "Cmd-click: unit test only", never NOT READ BACK.

private let url = "http://127.0.0.1:8080/links"

private func after(rows: Int, address: String = url, selected: Int? = 0) -> ProbeState {
    var state = ProbeState()
    state.rows = (0..<rows).map { "row \($0 + 1)" }
    state.address = address
    state.selected = selected
    return state
}

/// The ⌘-click did not arrive: 2 rows (after the menu part), the same page. The exact words of the ruling.
@Test func aClickThatDoesNotArriveIsUnitTestOnly() throws {
    #expect(try PageSteps.commandClickPart(after(rows: 2), url: url) == "Cmd-click: unit test only")
    #expect(PageSteps.commandClickUnitOnly == "Cmd-click: unit test only")
}

@Test func aClickThatOpensABackgroundTabIsSaid() throws {
    let line = try PageSteps.commandClickPart(after(rows: 3), url: url)
    #expect(line == "⌘-click on the link: 3 rows, row 1 still selected")
}

/// The ⌘-click arrived but did the wrong thing: a FAIL of the app, not "unit test only" and not NOT READ BACK.
@Test(arguments: [
    after(rows: 2, address: "http://127.0.0.1:8080/page/5"),  // the page itself followed the link
    after(rows: 3, selected: 2),                              // the new tab was selected
    after(rows: 3, address: "http://127.0.0.1:8080/page/5"),
    after(rows: 1),                                           // a row went away
])
func aClickThatArrivesWrongFails(state: ProbeState) {
    do {
        let line = try PageSteps.commandClickPart(state, url: url)
        Issue.record("no FAIL; the line said \"\(line)\"")
    } catch StepError.fail {
        // expected
    } catch {
        Issue.record("not a FAIL: \(error)")
    }
}
