import Foundation

/// A command line the tool does not understand. It stops the run with exit 2 before anything
/// runs, so a typo never falls back to a full run that overwrites _LATEST.md (NT-GAT-003).
/// The message goes to stderr and the `--log` file: the home folder reads `~` (P0-REV-3).
struct UsageError: Error {
    let message: String

    init(message: String) {
        self.message = Report.tilde(message)
    }
}

struct Options {
    static let usage = "usage: nhetrinh-readback [--steps R1,R2] [--app <path>] [--evidence <repo>] [--log <file>]"
        + " [--keep-capture <dir>] [--allow-focus] [--release-url <https …/nhetrinh-<version>-arm64.zip>]"
    var app = AppSession.installed
    var steps: Set<String> = []
    /// The repository's readback evidence folder, from `--evidence`; nil: found from the current directory.
    var evidence: URL?
    /// Where stdout and stderr go, from `--log`: `open` does not pass the app's stdout (NT-TG-003).
    var log: URL?
    /// Where R2 keeps its capture and its numbers, from `--keep-capture`; nil: nothing is kept.
    /// Never inside a repository: a capture is a picture of the screen, and the repository is public.
    var keepCapture: URL?
    /// D25 (amends D18): R26a and R26b may bring nhetrinh to the front and take the focus. A flag, no value.
    var allowFocus = false
    /// P8, R44: the released zip, from `--release-url` (https, a .zip). R44 runs only with it.
    var releaseURL: URL?

    /// `known`: the step ids that exist. Every flag but `--allow-focus` needs a value; each is given at most once: a
    /// repeated flag would keep only its last value (`--steps R1 --steps R2` ran R2 only).
    init(_ arguments: [String], known: Set<String>,
         exists: (String) -> Bool = { FileManager.default.fileExists(atPath: $0) }) throws {
        var rest = arguments.dropFirst()
        var seen: Set<String> = []
        while let flag = rest.popFirst() {
            guard Self.flags.contains(flag) else {
                throw UsageError(message: "unknown argument `\(flag)`")
            }
            guard seen.insert(flag).inserted else { throw UsageError(message: "`\(flag)` is given more than once") }
            if flag == "--allow-focus" {
                allowFocus = true
                continue
            }
            guard let value = rest.popFirst(), !value.isEmpty, !value.hasPrefix("--") else {
                throw UsageError(message: "`\(flag)` needs a value")
            }
            if flag == "--app" { app = URL(fileURLWithPath: value) }
            if flag == "--steps" { steps = try Self.stepIds(value, known: known) }
            if flag == "--evidence" { evidence = try Self.readbackFolder(value, exists: exists) }
            if flag == "--log" { log = try Self.absolute(value, flag: flag) }
            if flag == "--keep-capture" { keepCapture = try Self.outsideRepository(value, exists: exists) }
            if flag == "--release-url" { releaseURL = try Self.releaseZip(value) }
        }
    }

    static let flags = ["--app", "--steps", "--evidence", "--log", "--keep-capture", "--allow-focus", "--release-url"]

    /// Evidence is kept only for a full run on the installed app (R44 is never part of it).
    var keepsEvidence: Bool { steps.isEmpty && app == AppSession.installed && releaseURL == nil }

    /// Whether step `id` runs: the listed steps, or every step; R44 only with `--release-url`.
    func runs(_ id: String) -> Bool {
        guard steps.isEmpty else { return steps.contains(id) }
        return id != ReleaseCheck.step.id || releaseURL != nil
    }

    private static func releaseZip(_ value: String) throws -> URL {
        guard let url = URL(string: value), url.scheme == "https", url.host != nil, url.pathExtension == "zip" else {
            throw UsageError(message: "`--release-url` needs an https URL of a .zip")
        }
        return url
    }

    /// The `--log` file, read before the command line is checked so that a usage error lands in it too.
    static func logPath(_ arguments: [String]) -> URL? {
        guard let index = arguments.firstIndex(of: "--log"), index + 1 < arguments.count else { return nil }
        return try? absolute(arguments[index + 1], flag: "--log")
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

    /// An app launched by `open` runs in `/`, so a relative path would mean something else there.
    private static func absolute(_ value: String, flag: String) throws -> URL {
        guard value.hasPrefix("/") else { throw UsageError(message: "`\(flag)` needs an absolute path") }
        return URL(fileURLWithPath: value).standardizedFileURL.resolvingSymlinksInPath()
    }

    /// `folder` must be the repository or a folder in it; the report goes only to the repository's
    /// own evidence folder, never anywhere else.
    private static func readbackFolder(_ value: String, exists: (String) -> Bool) throws -> URL {
        let folder = try absolute(value, flag: "--evidence")
        guard let root = enclosing(folder, where: { isNhetrinh($0, exists) }) else {
            throw UsageError(message: "`--evidence` \(value) is not inside the nhetrinh repository")
        }
        return root.appendingPathComponent("hubs/failures/evidence/readback")
    }

    /// `--keep-capture` refuses the nhetrinh repository and any git repository or worktree (`.git`).
    private static func outsideRepository(_ value: String, exists: (String) -> Bool) throws -> URL {
        let folder = try absolute(value, flag: "--keep-capture")
        let inside = enclosing(folder) { isNhetrinh($0, exists) || exists($0.appendingPathComponent(".git").path) }
        if inside != nil {
            throw UsageError(message: "`--keep-capture` \(value) is inside a repository; a capture is never kept there")
        }
        return folder
    }

    private static func isNhetrinh(_ folder: URL, _ exists: (String) -> Bool) -> Bool {
        exists(folder.appendingPathComponent("hubs/failures/evidence").path)
            && exists(folder.appendingPathComponent("_app/Package.swift").path)
    }

    /// `folder` or the nearest folder above it that satisfies `match`; nil when none up to `/` does.
    private static func enclosing(_ folder: URL, where match: (URL) -> Bool) -> URL? {
        var folder = folder
        while true {
            if match(folder) { return folder }
            guard folder.path != "/" else { return nil }
            folder.deleteLastPathComponent()
        }
    }
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
