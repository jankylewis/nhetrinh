import Foundation

/// P10-PROFILE (D29): P9's layout moved to one folder per profile, at launch, before anything reads a file.
/// `Default`: each of P9's root files (`rootFiles`) into `Default/`; another profile: `profiles/<identifier>/`
/// renamed `<name>/` (each launch moves its own profile: an identifier cannot be turned back into a name).
/// Each move is one rename (atomic); a target that exists is kept and its source left untouched (counted
/// only). A move that fails puts back this run's moves and the launch uses the old folder: the tabs open as
/// in P9. Run again, it moves what is left: a crash in the middle is finished by the next launch.
public enum ProfileMigration {
    /// P9's files at the root: the session, its kept bad file and v1 backup, the prefs, the crash marker; and
    /// P11's history with SQLite's side files (P11 writes it at the root until P10 lands). The session stays first.
    public static let rootFiles = ["session.json", "session.bad.json", "session.v1.json",
                                   "prefs.json", "prefs.bad.json", "running.marker",
                                   "history.sqlite", "history.sqlite-wal", "history.sqlite-shm"]
    public typealias Move = (_ from: URL, _ to: URL) throws -> Void

    public struct Outcome: Equatable {
        /// The folder this launch reads and writes: the profile's own, or after a failure the old one.
        public var folder: URL
        public var moved = 0
        /// Sources left untouched because their target exists.
        public var kept = 0
        /// Why the migration stopped (no path, no name), or nil.
        public var failure: String?

        /// What the log says: counts and the failure's kind only.
        public var line: String {
            "profile: migrated \(moved), kept \(kept) (target exists)" + (failure.map { ", failed: \($0)" } ?? "")
        }
    }

    public static func run(_ layout: ProfileLayout, move: Move = FileManager.default.moveItem) -> Outcome {
        layout.isDefault ? runDefault(layout, move: move) : runNamed(layout, move: move)
    }

    private static func exists(_ url: URL) -> Bool { FileManager.default.fileExists(atPath: url.path) }

    private static func runDefault(_ layout: ProfileLayout, move: Move) -> Outcome {
        var outcome = Outcome(folder: layout.folder)
        let pending = rootFiles
            .map { (layout.root.appendingPathComponent($0), layout.folder.appendingPathComponent($0)) }
            .filter { exists($0.0) }
        guard !pending.isEmpty else { return outcome }
        do {
            try FileManager.default.createDirectory(at: layout.folder, withIntermediateDirectories: true)
        } catch {
            return Outcome(folder: layout.legacyFolder, failure: "the profile folder could not be made")
        }
        var done: [(URL, URL)] = []
        for (from, to) in pending {
            if exists(to) {
                outcome.kept += 1
                continue
            }
            do {
                try move(from, to)
                done.append((from, to))
            } catch {
                return putBack(done, layout, kept: outcome.kept, move: move)
            }
        }
        outcome.moved = done.count
        return outcome
    }

    /// This run's moves undone; the folder is the one that holds the session (the tabs).
    private static func putBack(_ done: [(URL, URL)], _ layout: ProfileLayout, kept: Int, move: Move) -> Outcome {
        var stuck = 0
        for (from, to) in done.reversed() {
            do { try move(to, from) } catch { stuck += 1 }
        }
        let session = rootFiles[0]
        let useNew = exists(layout.folder.appendingPathComponent(session))
            || !exists(layout.legacyFolder.appendingPathComponent(session))
        let why = "a move failed, \(done.count - stuck) put back" + (stuck > 0 ? ", \(stuck) could not be" : "")
        return Outcome(folder: useNew ? layout.folder : layout.legacyFolder, moved: stuck, kept: kept, failure: why)
    }

    private static func runNamed(_ layout: ProfileLayout, move: Move) -> Outcome {
        guard exists(layout.legacyFolder) else { return Outcome(folder: layout.folder) }
        guard !exists(layout.folder) else { return Outcome(folder: layout.folder, kept: 1) }
        do {
            try FileManager.default.createDirectory(at: layout.root, withIntermediateDirectories: true)
            try move(layout.legacyFolder, layout.folder)
            return Outcome(folder: layout.folder, moved: 1)
        } catch {
            return Outcome(folder: layout.legacyFolder, failure: "the old profile folder could not be moved")
        }
    }
}
