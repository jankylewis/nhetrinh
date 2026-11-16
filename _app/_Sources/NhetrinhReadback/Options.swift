import Foundation

/// A command line the tool does not understand. It stops the run with exit 2 before anything
/// runs, so a typo never falls back to a full run that overwrites _LATEST.md (NT-GAT-003).
struct UsageError: Error {
    let message: String
}

struct Options {
    static let usage = "usage: nhetrinh-readback [--steps R1,R2] [--app <path>] [--evidence <repo>] [--log <file>]"
    var app = AppSession.installed
    var steps: Set<String> = []
    /// The repository's readback evidence folder, from `--evidence`; nil: found from the current directory.
    var evidence: URL?
    /// Where stdout and stderr go, from `--log`: `open` does not pass the app's stdout (NT-TG-003).
    var log: URL?

    /// `known`: the step ids that exist. Every flag needs a value and is given at most once: a
    /// repeated flag would keep only its last value (`--steps R1 --steps R2` ran R2 only).
    init(_ arguments: [String], known: Set<String>,
         exists: (String) -> Bool = { FileManager.default.fileExists(atPath: $0) }) throws {
        var rest = arguments.dropFirst()
        var seen: Set<String> = []
        while let flag = rest.popFirst() {
            guard ["--app", "--steps", "--evidence", "--log"].contains(flag) else {
                throw UsageError(message: "unknown argument `\(flag)`")
            }
            guard seen.insert(flag).inserted else { throw UsageError(message: "`\(flag)` is given more than once") }
            guard let value = rest.popFirst(), !value.isEmpty, !value.hasPrefix("--") else {
                throw UsageError(message: "`\(flag)` needs a value")
            }
            if flag == "--app" { app = URL(fileURLWithPath: value) }
            if flag == "--steps" { steps = try Self.stepIds(value, known: known) }
            if flag == "--evidence" { evidence = try Self.readbackFolder(value, exists: exists) }
            if flag == "--log" { log = try Self.absolute(value, flag: flag) }
        }
    }

    /// Evidence is kept only for a full run on the installed app.
    var keepsEvidence: Bool { steps.isEmpty && app == AppSession.installed }

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
        var folder = try absolute(value, flag: "--evidence")
        while true {
            let hubs = folder.appendingPathComponent("hubs/failures/evidence")
            if exists(hubs.path) && exists(folder.appendingPathComponent("_app/Package.swift").path) {
                return hubs.appendingPathComponent("readback")
            }
            guard folder.path != "/" else { break }
            folder.deleteLastPathComponent()
        }
        throw UsageError(message: "`--evidence` \(value) is not inside the nhetrinh repository")
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
