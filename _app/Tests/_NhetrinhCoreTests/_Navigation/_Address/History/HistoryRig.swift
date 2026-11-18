import Foundation
import Testing
@testable import NhetrinhCore

// P11-HISTORY: every store a test opens lives in a new folder under the temporary folder (the brief's guard:
// no test opens a file outside it). Sites are example.test names; nothing reaches the network or the app's folder.

enum HistoryRig {
    /// A new, empty folder under the temporary folder; the guard fails the test for any other place.
    static func folder() throws -> URL {
        let temp = FileManager.default.temporaryDirectory.standardizedFileURL
        let url = temp.appendingPathComponent("history-\(UUID().uuidString)", isDirectory: true)
        try #require(isTemporary(url))
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    /// Whether `url` lies under the temporary folder.
    static func isTemporary(_ url: URL) -> Bool {
        let temp = FileManager.default.temporaryDirectory.standardizedFileURL.path
        return url.standardizedFileURL.path.hasPrefix(temp + "/")
    }

    /// A store in a new temporary folder.
    static func store(capacity: Int = HistoryStore.capacity) throws -> HistoryStore {
        let folder = try folder()
        let store = try HistoryStore(folder: folder, capacity: capacity)
        try #require(isTemporary(store.fileURL))
        return store
    }

    static let now = Date(timeIntervalSince1970: 1_800_000_000)

    static func daysAgo(_ days: Double) -> Date { now.addingTimeInterval(-days * 86_400) }

    /// `count` visits of `url`, the last one `days` ago; `typed` of them typed.
    static func visit(_ store: HistoryStore, _ url: String, title: String = "", times count: Int = 1,
                      timing: (typed: Int, days: Double) = (0, 0)) throws {
        for index in 0..<count {
            try store.record(url: url, title: title, typed: index < timing.typed, at: daysAgo(timing.days))
        }
    }

    /// The urls the store suggests for `typed`, best first.
    static func urls(_ store: HistoryStore, _ typed: String) throws -> [String] {
        try store.suggestions(for: typed, now: now).map(\.url)
    }
}

@Test func theGuardRefusesAFolderOutsideTheTemporaryFolder() {
    #expect(!HistoryRig.isTemporary(URL(fileURLWithPath: NSHomeDirectory())))
    #expect(!HistoryRig.isTemporary(FileManager.default.temporaryDirectory))
    #expect(HistoryRig.isTemporary(FileManager.default.temporaryDirectory.appendingPathComponent("x")))
}
