import Foundation
import Testing
@testable import NhetrinhReadback

/// One run; its verdicts decide the run's verdict line and exit code. The worst verdict wins,
/// wherever it is in the run, and a run where no step ran is never a pass (NT-GAT-003).
struct RunCase: CustomTestStringConvertible {
    let verdicts: [Verdict]
    let verdictLine: String
    let exitCode: Int32

    var testDescription: String { verdicts.isEmpty ? "no step" : verdicts.map(\.rawValue).joined(separator: ", ") }

    var results: [StepResult] {
        verdicts.enumerated().map { StepResult(id: "R\($0 + 1)", name: "step", verdict: $1, detail: "seen") }
    }
}

let runCases = [
    RunCase(verdicts: [.pass, .pass], verdictLine: "verdict: PASS (2 of 2)", exitCode: 0),
    RunCase(verdicts: [.pass, .fail], verdictLine: "verdict: FAIL (1 passed, 1 failed, 0 not read back)", exitCode: 1),
    RunCase(verdicts: [.fail, .pass], verdictLine: "verdict: FAIL (1 passed, 1 failed, 0 not read back)", exitCode: 1),
    RunCase(verdicts: [.pass, .notReadBack],
            verdictLine: "verdict: INCOMPLETE (1 passed, 0 failed, 1 not read back)", exitCode: 2),
    RunCase(verdicts: [.notReadBack, .pass],
            verdictLine: "verdict: INCOMPLETE (1 passed, 0 failed, 1 not read back)", exitCode: 2),
    RunCase(verdicts: [.notReadBack, .fail, .notReadBack],
            verdictLine: "verdict: FAIL (0 passed, 1 failed, 2 not read back)", exitCode: 1),
    RunCase(verdicts: [.fail, .notReadBack],
            verdictLine: "verdict: FAIL (0 passed, 1 failed, 1 not read back)", exitCode: 1),
    RunCase(verdicts: [], verdictLine: "verdict: INCOMPLETE (no step ran)", exitCode: 2),
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
    for result in run.results {
        #expect(text.contains("| \(result.id) step | \(result.verdict.rawValue) | seen |"))
    }
}

/// The report is kept in a public repository: the home folder is written `~` (law 8), and only
/// as a whole path part, so another folder that starts with the same letters stays as it is.
let homePaths: [(text: String, written: String)] = [
    ("/Users/someone/Applications/nhetrinh.app", "~/Applications/nhetrinh.app"),
    ("saved /Users/someone/x.png and /Users/someone/y.png", "saved ~/x.png and ~/y.png"),
    ("/Users/someone", "~"),
    ("/Users/someone2/x.png", "/Users/someone2/x.png"),
    ("/Users/someone.old/x.png", "/Users/someone.old/x.png"),
]

@Test(arguments: homePaths)
func homeFolderIsWrittenAsTilde(path: (text: String, written: String)) {
    #expect(Report.tilde(path.text, home: "/Users/someone") == path.written)
}

/// D23 (P0-PROBE-FIX gap 4): only R2 uses Accessibility; the header must not say every step does.
/// P1-FIX-1: it names every probe step, R9-R12 included.
@Test func headerSaysHowEachStepActs() {
    let text = Report.text([], app: URL(fileURLWithPath: "/nowhere/nhetrinh.app"))
    #expect(!text.contains("A step acts on the app through the Accessibility API"))
    #expect(text.contains("R1, R3-R7 and R9-R12 act through the app's readback probe (`NHT_READBACK=1`, D23)"))
    #expect(text.contains("R2 reads the Dock through the Accessibility API") && text.contains("R8"))
}

@Test func reportHasNoHomePath() {
    let home = FileManager.default.homeDirectoryForCurrentUser.path
    let result = StepResult(id: "R2", name: "dock", verdict: .pass, detail: "saved \(home)/capture.png")
    let text = Report.text([result], app: AppSession.installed)
    #expect(!text.contains(home))
    #expect(text.contains("~/Applications/nhetrinh.app") && text.contains("saved ~/capture.png"))
}

/// P0-SIGN-1. A step without a grant is NOT READ BACK; its reason must name the app that lacks
/// the grant: nhetrinh-readback.app when the tool runs as that app, the terminal otherwise.
/// Only a name, never a path (the report is public).
let granteeCases: [(bundlePath: String, grantee: String)] = [
    ("/Applications/nhetrinh-readback.app", "nhetrinh-readback.app"),
    ("/repo/_app/build/nhetrinh-readback.app", "nhetrinh-readback.app"),
    ("/repo/_app/.build/arm64-apple-macosx/release", "the terminal app"),
    ("/repo/_app/.build/debug", "the terminal app"),
]

@Test(arguments: granteeCases)
func granteeIsTheAppThatRuns(bundlePath: String, grantee: String) {
    #expect(Grant.grantee(bundlePath: bundlePath) == grantee)
}

@Test(arguments: granteeCases)
func missingGrantNamesTheGranteeAndNoPath(bundlePath: String, grantee: String) {
    for reason in [Grant.noAccessibility(bundlePath: bundlePath), Grant.noScreenRecording(bundlePath: bundlePath)] {
        #expect(reason.hasPrefix(grantee + " has no "), "\(reason)")
        #expect(!reason.contains("/"), "\(reason)")
    }
}
