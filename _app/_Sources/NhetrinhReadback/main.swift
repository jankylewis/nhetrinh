import Foundation

// nhetrinh-readback: use the installed app as its end user and say what happened, step by step.
//
//   swift run nhetrinh-readback                     every step, on ~/Applications/nhetrinh.app;
//                                                   the verdict is kept in hubs/failures/evidence/readback/
//   swift run nhetrinh-readback --steps R1,R2       only these steps (nothing is kept)
//   swift run nhetrinh-readback --app <path>        another copy of the app (nothing is kept)
//
// Exit code: 0 every step passed, 1 a step failed, 2 a step could not run (NOT READ BACK), no step
// ran, or the command line is wrong (nothing runs then).

/// A command line the tool does not understand. It stops the run with exit 2 before anything
/// runs, so a typo never falls back to a full run that overwrites _LATEST.md (NT-GAT-003).
struct UsageError: Error {
    let message: String
}

struct Options {
    var app = AppSession.installed
    var steps: Set<String> = []

    /// `known`: the step ids that exist. Every flag needs a value.
    init(_ arguments: [String], known: Set<String>) throws {
        var rest = arguments.dropFirst()
        while let flag = rest.popFirst() {
            guard flag == "--app" || flag == "--steps" else { throw UsageError(message: "unknown argument `\(flag)`") }
            guard let value = rest.popFirst(), !value.isEmpty, !value.hasPrefix("--") else {
                throw UsageError(message: "`\(flag)` needs a value")
            }
            if flag == "--app" { app = URL(fileURLWithPath: value) }
            if flag == "--steps" { steps = try Self.stepIds(value, known: known) }
        }
    }

    private static func stepIds(_ value: String, known: Set<String>) throws -> Set<String> {
        let ids = Set(value.split(separator: ",").map(String.init))
        guard !ids.isEmpty else { throw UsageError(message: "`--steps` lists no step") }
        let unknown = ids.subtracting(known).sorted()
        guard unknown.isEmpty else {
            let all = known.sorted().joined(separator: ",")
            throw UsageError(message: "no step \(unknown.joined(separator: ", ")); the steps are \(all)")
        }
        return ids
    }

    /// Evidence is kept only for a full run on the installed app.
    var keepsEvidence: Bool { steps.isEmpty && app == AppSession.installed }
}

/// The repository's evidence folder, found from the current directory; nil outside the repository.
func evidenceFolder() -> URL? {
    var folder = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    for _ in 0..<6 {
        let hubs = folder.appendingPathComponent("hubs/failures/evidence")
        if FileManager.default.fileExists(atPath: hubs.path) { return hubs.appendingPathComponent("readback") }
        folder.deleteLastPathComponent()
    }
    return nil
}

let options: Options
do {
    options = try Options(CommandLine.arguments, known: Set(BaseSteps.all.map(\.id)))
} catch {
    let message = (error as? UsageError)?.message ?? "\(error)"
    let usage = "usage: nhetrinh-readback [--steps R1,R2] [--app <path>]"
    FileHandle.standardError.write(Data("usage error: \(message)\n\(usage)\n".utf8))
    exit(2)
}
guard FileManager.default.fileExists(atPath: options.app.path) else {
    print("no app at \(options.app.path); run _app/scripts/install.sh first")
    exit(2)
}
let kept = options.keepsEvidence ? evidenceFolder() : nil
if let kept {
    try FileManager.default.createDirectory(at: kept, withIntermediateDirectories: true)
    SystemSteps.evidenceFolder = kept
}
let session = AppSession(appURL: options.app)
let steps = BaseSteps.all.filter { options.steps.isEmpty || options.steps.contains($0.id) }
let results = Runner.run(steps, in: session)
session.quit()
let text = Report.text(results, app: options.app)
print(text)
if let kept { try Report.write(text, to: kept) }
exit(Report.exitCode(results))
