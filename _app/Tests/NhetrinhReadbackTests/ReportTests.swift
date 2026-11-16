import Foundation
import Testing
@testable import NhetrinhReadback

/// One run of two steps; the second step's verdict changes the run's verdict and exit code.
struct RunCase: CustomTestStringConvertible {
    let second: Verdict
    let verdictLine: String
    let exitCode: Int32

    var testDescription: String { "second step \(second.rawValue)" }

    var results: [StepResult] {
        [StepResult(id: "R1", name: "first", verdict: .pass, detail: "seen"),
         StepResult(id: "R2", name: "second", verdict: second, detail: "seen")]
    }
}

let runCases = [
    RunCase(second: .pass, verdictLine: "verdict: PASS (2 of 2)", exitCode: 0),
    RunCase(second: .fail, verdictLine: "verdict: FAIL (1 passed, 1 failed, 0 not read back)", exitCode: 1),
    RunCase(second: .notReadBack, verdictLine: "verdict: INCOMPLETE (1 passed, 0 failed, 1 not read back)",
            exitCode: 2),
]

@Test(arguments: runCases)
func exitCodeFollowsTheWorstVerdict(run: RunCase) {
    #expect(Report.exitCode(run.results) == run.exitCode)
}

@Test(arguments: runCases)
func verdictLineCountsEveryVerdict(run: RunCase) {
    let text = Report.text(run.results, app: URL(fileURLWithPath: "/nowhere/nhetrinh.app"))
    let line = text.split(separator: "\n").first { $0.hasPrefix("verdict: ") }
    #expect(line.map(String.init) == run.verdictLine)
}

@Test(arguments: runCases)
func everyStepHasItsRow(run: RunCase) {
    let text = Report.text(run.results, app: URL(fileURLWithPath: "/nowhere/nhetrinh.app"))
    #expect(text.contains("| R2 second | \(run.second.rawValue) | seen |"))
}
