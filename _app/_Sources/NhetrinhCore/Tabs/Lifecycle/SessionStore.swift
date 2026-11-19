import Foundation

/// Reads and writes `session.json` in a folder (the app passes its profile's folder: `ProfileLayout`, D29).
/// A file that cannot be read (corrupt, or from a newer version) is renamed `session.bad.json`,
/// and the app starts with one home tab: no crash, no silent loss.
public enum SessionStore {
    public static let fileName = "session.json"
    public static let badFileName = "session.bad.json"

    /// Atomic: the folder holds the old file or the new one, never half of one.
    public static func save(_ session: Session, in folder: URL) throws {
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        try encoder.encode(session).write(to: folder.appendingPathComponent(fileName), options: .atomic)
    }

    /// The saved session; `Session.home(home)` when there is none, it has no tab, or it is bad.
    /// `report` hears why a file was not used (the app logs it): nothing is dropped in silence.
    public static func load(from folder: URL, home: URL, report: (String) -> Void = { _ in }) -> Session {
        let file = folder.appendingPathComponent(fileName)
        guard let bytes = try? Data(contentsOf: file) else { return .home(home) }
        guard let session = decode(bytes) else {
            report(keepBad(file, in: folder))
            return .home(home)
        }
        return session.tabs.isEmpty ? .home(home) : session.clamped
    }

    /// A session of this version or older; nil for anything else. The version is read first, so a
    /// newer file is refused even when its fields happen to decode.
    static func decode(_ bytes: Data) -> Session? {
        struct Head: Decodable { let version: Int }
        guard let head = try? JSONDecoder().decode(Head.self, from: bytes),
              head.version >= 1, head.version <= Session.currentVersion else { return nil }
        return try? JSONDecoder().decode(Session.self, from: bytes)
    }

    /// Move the bad file aside (an older bad file is replaced) and say what happened.
    static func keepBad(_ file: URL, in folder: URL) -> String {
        let bad = folder.appendingPathComponent(badFileName)
        do {
            if FileManager.default.fileExists(atPath: bad.path) { try FileManager.default.removeItem(at: bad) }
            try FileManager.default.moveItem(at: file, to: bad)
            return "\(fileName) could not be read (corrupt or newer); kept as \(badFileName)"
        } catch {
            return "\(fileName) could not be read, and keeping it as \(badFileName) failed: \(error)"
        }
    }
}
