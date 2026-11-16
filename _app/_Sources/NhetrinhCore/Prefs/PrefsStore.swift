import Foundation

/// Reads and writes `prefs.json` in the session's folder (`SessionStore.folder`: per profile).
/// A file that cannot be read gives the defaults and is kept as `prefs.bad.json`: no crash, no silent loss.
public enum PrefsStore {
    public static let fileName = "prefs.json"
    public static let badFileName = "prefs.bad.json"

    /// Atomic: the folder holds the old file or the new one, never half of one.
    public static func save(_ prefs: Prefs, in folder: URL) throws {
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        try prefs.encoded().write(to: folder.appendingPathComponent(fileName), options: .atomic)
    }

    /// The saved prefs; the defaults when there are none or the file is bad (`report` hears why).
    public static func load(from folder: URL, report: (String) -> Void = { _ in }) -> Prefs {
        let file = folder.appendingPathComponent(fileName)
        guard let bytes = try? Data(contentsOf: file) else { return Prefs() }
        if let prefs = Prefs.decode(bytes) { return prefs }
        let bad = folder.appendingPathComponent(badFileName)
        do {
            if FileManager.default.fileExists(atPath: bad.path) { try FileManager.default.removeItem(at: bad) }
            try FileManager.default.moveItem(at: file, to: bad)
            report("\(fileName) could not be read; kept as \(badFileName), the defaults are used")
        } catch {
            report("\(fileName) could not be read, and keeping it as \(badFileName) failed: \(error)")
        }
        return Prefs()
    }
}
