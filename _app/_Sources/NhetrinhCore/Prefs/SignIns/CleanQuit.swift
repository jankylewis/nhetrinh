import Foundation

/// P9-REMEMBER (D28): sign-ins come back only after a clean quit. A marker file is written at launch and
/// removed at a clean quit; found at launch, the last run ended otherwise (a crash, a kill).
public struct CleanQuitMarker {
    public static let fileName = "running.marker"
    public let file: URL

    public init(folder: URL) {
        file = folder.appendingPathComponent(Self.fileName)
    }

    /// At launch: whether the last run did not quit cleanly; then marks this run.
    public func launch() throws -> Bool {
        let crashed = FileManager.default.fileExists(atPath: file.path)
        let folder = file.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        try Data().write(to: file, options: .atomic)
        return crashed
    }

    /// At a clean quit: no marker afterwards.
    public func clear() throws {
        guard FileManager.default.fileExists(atPath: file.path) else { return }
        try FileManager.default.removeItem(at: file)
    }
}
