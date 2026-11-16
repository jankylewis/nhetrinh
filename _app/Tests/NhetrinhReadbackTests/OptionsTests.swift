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
