import Foundation

/// The readback's verdict as text: printed, and kept as evidence in
/// hubs/failures/evidence/readback/_LATEST.md after a full run on the installed app.
enum Report {
    /// `ending`: how the run's own app instance ended (NT-TG-004); nil says nothing about it.
    /// `allowFocus`: the run had `--allow-focus` (D25); the header says so.
    static func text(_ results: [StepResult], app: URL, ending: QuitOutcome? = nil,
                     allowFocus: Bool = false) -> String {
        let failed = results.filter { $0.verdict == .fail }.count
        let skipped = results.filter { $0.verdict == .notReadBack }.count
        let passed = results.count - failed - skipped
        var verdict = "PASS (\(passed) of \(results.count))"
        if failed > 0 || skipped > 0 {
            let word = failed > 0 ? "FAIL" : "INCOMPLETE"
            verdict = "\(word) (\(passed) passed, \(failed) failed, \(skipped) not read back)"
        }
        if results.isEmpty { verdict = "INCOMPLETE (no step ran)" }  // nothing read back is never a pass
        var lines = [
            "# Readback — latest run", "",
            "date: \(timestamp())",
            "app: \(tilde(app.path)), version \(plist(app, "CFBundleShortVersionString")), "
                + "built from commit \(plist(app, "NHTCommit"))",
            "verdict: \(verdict)", "",
            "Each step acts on the app as a user would and says what it saw. "
                + "R1, R3-R7 and R9-R26b act through the app's readback probe (`NHT_READBACK=1`, D23), "
                + "along the user's own paths;",
            "R2 reads the Dock through the Accessibility API; R8 measures a normal launch, without the probe.",
            "NOT READ BACK means the step could not run. It is never counted as passed.",
            allowFocus ? "focus: R26a, R26b may take the focus (--allow-focus, D25); each says so on its line"
                : "focus: never taken (D18); R26a, R26b need --allow-focus (D25)", "",
            "| Step | Verdict | What the readback did and saw |", "|---|---|---|",
        ]
        lines += results.map { "| \($0.id) \($0.name) | \($0.verdict.rawValue) | \(tilde($0.detail)) |" }
        if let ending { lines += ["", ending.line] }
        return lines.joined(separator: "\n") + "\n"
    }

    static func write(_ text: String, to folder: URL) throws {
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        try Data(text.utf8).write(to: folder.appendingPathComponent("_LATEST.md"), options: .atomic)
    }

    /// 0 = every step passed; 1 = a step failed; 2 = no failure, but a step could not run, or no step ran.
    static func exitCode(_ results: [StepResult]) -> Int32 {
        if results.contains(where: { $0.verdict == .fail }) { return 1 }
        return results.isEmpty || results.contains { $0.verdict == .notReadBack } ? 2 : 0
    }

    /// The last line of a `--log` file: `open -W` returns 0 whatever the app's exit code.
    static func exitLine(_ code: Int32) -> String { "exit: \(code)" }

    private static func plist(_ app: URL, _ key: String) -> String {
        let file = app.appendingPathComponent("Contents/Info.plist")
        let values = NSDictionary(contentsOf: file) as? [String: Any]
        return values?[key] as? String ?? "unknown"
    }

    private static func timestamp() -> String {
        let format = DateFormatter()
        format.dateFormat = "yyyy-MM-dd HH:mm xxx"
        return format.string(from: Date())
    }

    /// Never write a personal path into the evidence: the home folder becomes `~`, only as a whole
    /// path part (`/Users/someone2` is another folder and stays as it is).
    static func tilde(_ text: String, home: String = FileManager.default.homeDirectoryForCurrentUser.path) -> String {
        let pattern = NSRegularExpression.escapedPattern(for: home) + "(?![A-Za-z0-9._-])"
        guard !home.isEmpty, let expression = try? NSRegularExpression(pattern: pattern) else { return text }
        let range = NSRange(text.startIndex..., in: text)
        return expression.stringByReplacingMatches(in: text, range: range, withTemplate: "~")
    }
}
