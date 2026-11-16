import Foundation

// nhetrinh-readback: use the installed app as its end user and say what happened, step by step.
// R1, R3-R7 and R9-R12 go through the app's readback probe (D23) and need no permission: they run from any
// terminal. R2 reads the Dock: it needs Accessibility and Screen Recording (NT-TG-003).
//
//   swift run nhetrinh-readback                     every step, on ~/Applications/nhetrinh.app;
//                                                   the verdict is kept in hubs/failures/evidence/readback/
//   swift run nhetrinh-readback --steps R1,R2       only these steps (nothing is kept)
//   swift run nhetrinh-readback --app <path>        another copy of the app (nothing is kept)
//   --evidence <repo>   keep the verdict in this repository (for nhetrinh-readback.app, which runs in /)
//   --log <file>        stdout and stderr go to this file, its last line `exit: <code>` (NT-TG-003)
//   --keep-capture <dir>  R2 keeps its capture and its numbers in <dir>, never inside a repository;
//                         without it the capture is deleted at once and nothing is kept
//
// Exit code: 0 every step passed, 1 a step failed, 2 a step could not run (NOT READ BACK), no step
// ran, or the command line is wrong (nothing runs then).

// `open -W` returns 0 whatever the exit code, so with a log the code is its last line.
func finish(_ code: Int32) -> Never {
    if Options.logPath(CommandLine.arguments) != nil { print(Report.exitLine(code)) }
    exit(code)
}

if let log = Options.logPath(CommandLine.arguments) {
    guard FileManager.default.createFile(atPath: log.path, contents: nil),
          let handle = FileHandle(forWritingAtPath: log.path) else { exit(2) }
    dup2(handle.fileDescriptor, STDOUT_FILENO)
    dup2(handle.fileDescriptor, STDERR_FILENO)
    setvbuf(stdout, nil, _IOLBF, 0)
}
let allSteps = BaseSteps.all + LifecycleSteps.all
let options: Options
do {
    options = try Options(CommandLine.arguments, known: Set(allSteps.map(\.id)))
} catch {
    let message = (error as? UsageError)?.message ?? "\(error)"
    FileHandle.standardError.write(Data("usage error: \(message)\n\(Options.usage)\n".utf8))
    finish(2)
}
guard FileManager.default.fileExists(atPath: options.app.path) else {
    print("no app at \(Report.tilde(options.app.path)); run _app/scripts/install/_install.sh first")
    finish(2)
}
// Every run starts without a saved session of the readback profile (P1), so R1 sees one home tab.
LifecycleSteps.forgetSession()
let kept = options.keepsEvidence ? options.evidence ?? evidenceFolder() : nil
let session = AppSession(appURL: options.app)
session.keepCapture = options.keepCapture
let steps = allSteps.filter { options.steps.isEmpty || options.steps.contains($0.id) }
let results = Runner.run(steps, in: session)
let ending = session.quit()
FileHandle.standardError.write(Data((ending.line + "\n").utf8))
let text = Report.text(results, app: options.app, ending: ending)
print(text)
do {
    if let kept { try Report.write(text, to: kept) }
} catch {
    print("could not keep the verdict in \(Report.tilde(kept?.path ?? "")): \(error)")
    finish(2)
}
finish(Report.exitCode(results))
