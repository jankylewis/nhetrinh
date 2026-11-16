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

let commandLines = [
    CommandLineCase(arguments: ["readback"], app: AppSession.installed, steps: [], keepsEvidence: true),
    CommandLineCase(arguments: ["readback", "--steps", "R1,R2"], app: AppSession.installed,
                    steps: ["R1", "R2"], keepsEvidence: false),
    CommandLineCase(arguments: ["readback", "--app", "/tmp/copy.app"], app: URL(fileURLWithPath: "/tmp/copy.app"),
                    steps: [], keepsEvidence: false),
    CommandLineCase(arguments: ["readback", "--steps", "R3", "--app", "/tmp/copy.app"],
                    app: URL(fileURLWithPath: "/tmp/copy.app"), steps: ["R3"], keepsEvidence: false),
    CommandLineCase(arguments: ["readback", "--steps"], app: AppSession.installed, steps: [], keepsEvidence: true),
]

@Test(arguments: commandLines)
func optionsSelectAppAndSteps(line: CommandLineCase) {
    let options = Options(line.arguments)
    #expect(options.app == line.app)
    #expect(options.steps == line.steps)
    #expect(options.keepsEvidence == line.keepsEvidence)
}
