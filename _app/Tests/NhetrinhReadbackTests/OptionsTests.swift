import Foundation
import Testing
@testable import NhetrinhReadback

/// Command lines of `nhetrinh-readback` and what they must select. Only a full run on the
/// installed app keeps evidence.
struct CommandLineCase: CustomTestStringConvertible {
    let arguments: [String]
    let app: URL
    let steps: Set<String>
    let keepsEvidence: Bool

    var testDescription: String { arguments.dropFirst().joined(separator: " ") }
}

let known: Set<String> = ["R1", "R2", "R3", "R8"]

let commandLines = [
    CommandLineCase(arguments: ["readback"], app: AppSession.installed, steps: [], keepsEvidence: true),
    CommandLineCase(arguments: ["readback", "--steps", "R1,R2"], app: AppSession.installed,
                    steps: ["R1", "R2"], keepsEvidence: false),
    CommandLineCase(arguments: ["readback", "--app", "/tmp/copy.app"], app: URL(fileURLWithPath: "/tmp/copy.app"),
                    steps: [], keepsEvidence: false),
    CommandLineCase(arguments: ["readback", "--steps", "R3", "--app", "/tmp/copy.app"],
                    app: URL(fileURLWithPath: "/tmp/copy.app"), steps: ["R3"], keepsEvidence: false),
]

@Test(arguments: commandLines)
func optionsSelectAppAndSteps(line: CommandLineCase) throws {
    let options = try Options(line.arguments, known: known)
    #expect(options.app == line.app)
    #expect(options.steps == line.steps)
    #expect(options.keepsEvidence == line.keepsEvidence)
}

/// A mistyped command line must stop with a usage error (exit 2). It must never fall back to a
/// full run: a full run overwrites hubs/failures/evidence/readback/_LATEST.md (NT-GAT-003).
let badCommandLines: [[String]] = [
    ["readback", "--step", "R8"],
    ["readback", "--steps"],
    ["readback", "--steps", ""],
    ["readback", "--steps", "R9"],
    ["readback", "--steps", "R1,R9"],
    ["readback", "--app"],
    ["readback", "R8"],
]

@Test(arguments: badCommandLines)
func badCommandLineIsAUsageError(arguments: [String]) {
    #expect(throws: UsageError.self) { try Options(arguments, known: known) }
}

/// P0-REV-1 gap: a repeated flag silently keeps only its last value (`--steps R1 --steps R2` runs R2 only).
let repeatedFlags = [
    ["readback", "--steps", "R1", "--steps", "R2"],
    ["readback", "--app", "/tmp/a.app", "--app", "/tmp/b.app"],
]

@Test(arguments: repeatedFlags)
func repeatedFlagIsAUsageError(arguments: [String]) {
    #expect(throws: UsageError.self) { try Options(arguments, known: known) }
}

/// P0-RBK-3: launched as nhetrinh-readback.app (`open -W -n ... --args`), the tool runs with `/` as
/// its current directory and no stdout. `--evidence` names the repository, `--log` the output file.
/// A fake repository at /repo: only these paths exist.
let fakeRepo: Set<String> = ["/repo/hubs/failures/evidence", "/repo/_app/Package.swift"]
let inFakeRepo: (String) -> Bool = { fakeRepo.contains($0) }
let fakeReadback = URL(fileURLWithPath: "/repo/hubs/failures/evidence/readback")

@Test(arguments: ["/repo", "/repo/_app/scripts", "/repo/hubs/../_app"])
func evidenceFindsTheRepositorysReadbackFolder(folder: String) throws {
    let options = try Options(["readback", "--evidence", folder], known: known, exists: inFakeRepo)
    #expect(options.evidence == fakeReadback)
    #expect(options.keepsEvidence)
}

@Test func logIsAnAbsoluteFile() throws {
    let options = try Options(["readback", "--log", "/repo/run.log", "--steps", "R1"], known: known, exists: inFakeRepo)
    #expect(options.log == URL(fileURLWithPath: "/repo/run.log"))
    #expect(options.evidence == nil)
    #expect(!options.keepsEvidence)
}

/// A path outside the repository, a relative path (open's current directory is `/`) and a
/// repeated flag are usage errors: the report is never written outside the repository.
let badAppFlags: [[String]] = [
    ["readback", "--evidence", "/elsewhere"],
    ["readback", "--evidence", "/"],
    ["readback", "--evidence", "/repo/../etc"],
    ["readback", "--evidence", "repo"],
    ["readback", "--evidence"],
    ["readback", "--evidence", "/repo", "--evidence", "/repo"],
    ["readback", "--log", "run.log"],
    ["readback", "--log"],
    ["readback", "--log", "/repo/a.log", "--log", "/repo/b.log"],
]

@Test(arguments: badAppFlags)
func badAppFlagIsAUsageError(arguments: [String]) {
    #expect(throws: UsageError.self) { try Options(arguments, known: known, exists: inFakeRepo) }
}

/// The log is opened before the command line is checked, so a usage error lands in it too.
@Test(arguments: [
    (["readback", "--log", "/repo/run.log", "--step", "R1"], "/repo/run.log" as String?),
    (["readback", "--steps", "R1"], nil),
    (["readback", "--log", "run.log"], nil),
    (["readback", "--log"], nil),
])
func logIsFoundBeforeTheCommandLineIsChecked(arguments: [String], path: String?) {
    #expect(Options.logPath(arguments) == path.map { URL(fileURLWithPath: $0) })
}

/// `open -W` returns 0 whatever the app's exit code (seen 2026-11-16), so the last log line holds it.
@Test(arguments: [Int32(0), 1, 2])
func lastLogLineHoldsTheExitCode(code: Int32) {
    #expect(Report.exitLine(code) == "exit: \(code)")
}

/// P0-REV-3 gap. main.swift writes a usage error to stderr; with `--log` it lands in the log that
/// readback_app.sh prints. The home folder in a path given to `--evidence` must read `~` there.
@Test func usageErrorNamesNoPersonalPath() {
    let home = FileManager.default.homeDirectoryForCurrentUser.path
    do {
        _ = try Options(["readback", "--evidence", home + "/elsewhere"], known: known, exists: inFakeRepo)
        Issue.record("a path outside the repository is a usage error")
    } catch let error as UsageError {
        #expect(!error.message.contains(home), "\(Report.tilde(error.message))")
    } catch {
        Issue.record("not a UsageError: \(error)")
    }
}
