import Foundation
@testable import NhetrinhCore

/// A throwaway Application Support folder: no test reaches the real one.
final class MigrationRig {
    let support = FileManager.default.temporaryDirectory.appendingPathComponent("nhetrinh-mig-\(UUID())")
    var root: URL { support.appendingPathComponent("nhetrinh", isDirectory: true) }

    deinit { try? FileManager.default.removeItem(at: support) }

    func layout(_ profile: String? = nil) -> ProfileLayout {
        guard let layout = ProfileLayout(applicationSupport: support, profile: profile) else {
            preconditionFailure("a refused profile in a test")
        }
        return layout
    }

    /// `text` written to `name` under the root (folders made).
    func put(_ name: String, _ text: String = "x") throws {
        let url = root.appendingPathComponent(name)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data(text.utf8).write(to: url)
    }

    func read(_ name: String) -> String? {
        (try? Data(contentsOf: root.appendingPathComponent(name))).map { String(decoding: $0, as: UTF8.self) }
    }

    func exists(_ name: String) -> Bool {
        FileManager.default.fileExists(atPath: root.appendingPathComponent(name).path)
    }

    /// A move that fails on the `failAt`-th call (1-based); the others are FileManager's own.
    static func failing(at failAt: Int) -> (ProfileMigration.Move, () -> Int) {
        var calls = 0
        let move: ProfileMigration.Move = { from, to in
            calls += 1
            if calls == failAt { throw CocoaError(.fileWriteNoPermission) }
            try FileManager.default.moveItem(at: from, to: to)
        }
        return (move, { calls })
    }
}
