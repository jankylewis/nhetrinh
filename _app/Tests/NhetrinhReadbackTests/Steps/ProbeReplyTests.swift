import Foundation
import NhetrinhCore
import Testing
@testable import NhetrinhReadback

/// D23: R1, R3-R7 read and act through the app's readback probe. What the probe answers decides
/// the verdict: an action the app refuses is FAIL, a probe that cannot be reached is NOT READ BACK.
struct RowIndexCase: CustomTestStringConvertible {
    let fromEnd: Int
    let count: Int
    let index: Int?

    var testDescription: String { "\(fromEnd) from the end of \(count) rows" }
}

@Test("the row counted from the end", arguments: [
    RowIndexCase(fromEnd: 0, count: 2, index: 1),
    RowIndexCase(fromEnd: 1, count: 2, index: 0),
    RowIndexCase(fromEnd: 1, count: 5, index: 3),
    RowIndexCase(fromEnd: 2, count: 2, index: nil),
    RowIndexCase(fromEnd: 0, count: 0, index: nil),
    RowIndexCase(fromEnd: -1, count: 3, index: nil),
])
func rowIndexFromEnd(_ row: RowIndexCase) {
    #expect(ProbeReply.rowIndex(fromEnd: row.fromEnd, count: row.count) == row.index)
}

private func verdict(_ act: @escaping () throws -> Void) -> (Verdict, String) {
    let step = Step(id: "R0", name: "probe", run: { _ in try act(); return "ok" })
    let result = Runner.run([step], in: AppSession(appURL: AppSession.installed))[0]
    return (result.verdict, result.detail)
}

@Test("a state answer is the state; anything else is not read back", arguments: [
    (ProbeResponse.state(ProbeState()), Verdict.pass),
    (.done, .notReadBack),
    (.failed("the browser window is gone"), .notReadBack),
])
func stateAnswer(response: ProbeResponse, expected: Verdict) {
    #expect(verdict { _ = try ProbeReply.state(response) }.0 == expected)
}

@Test("an action the app refuses is FAIL with its reason; a state answer is not read back", arguments: [
    (ProbeResponse.done, Verdict.pass, ""),
    (.failed("no menu item File > New Tab"), .fail, "File > New Tab: no menu item File > New Tab"),
    (.state(ProbeState()), .notReadBack, "File > New Tab: the probe answered a state, not an action"),
])
func actionAnswer(response: ProbeResponse, expected: Verdict, detail: String) {
    let (seen, why) = verdict { try ProbeReply.acted(response, doing: "File > New Tab") }
    #expect(seen == expected)
    if expected != .pass { #expect(why == detail) }
}

@Test("an unreachable probe is not read back, names the cause, and no path", arguments: [
    ProbeError.system("connect", ENOENT), .noAnswer, .pathTooLong,
])
func unreachableProbe(error: ProbeError) {
    let (seen, why) = verdict { throw ProbeReply.unreachable(error) }
    #expect(seen == .notReadBack)
    #expect(why.hasPrefix("the app answers no readback probe (NHT_READBACK=1): \(error.description)"))
    #expect(why.contains("D23"))
    #expect(!why.contains("/"))
}
