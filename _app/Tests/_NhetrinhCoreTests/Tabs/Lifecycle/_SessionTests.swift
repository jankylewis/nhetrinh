import Foundation
import Testing
@testable import NhetrinhCore

// P1 tests (hubs/product/plan/M1_DAILY_DRIVER.md), written red first on stubs (P1-PREP-1, DECISIONS.md D22);
// green since P1-BUILD-1 built Session and SessionStore.

private let home = URL(string: "https://www.google.com") ?? URL(fileURLWithPath: "/")

/// A new empty folder per test (the tests run in parallel), removed by `body`'s caller.
private func inFolder(_ body: (URL) throws -> Void) throws {
    let folder = FileManager.default.temporaryDirectory.appendingPathComponent("nhetrinh-session-\(UUID())")
    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: folder) }
    try body(folder)
}

private func tabs(_ count: Int) -> [SessionTab] {
    (0..<count).compactMap { index in
        URL(string: "https://example.com/\(index)?q=a%20b").map { SessionTab(url: $0, title: "Tab \(index)") }
    }
}

struct RoundTripCase: CustomTestStringConvertible {
    let testDescription: String
    let session: Session
}

let roundTripCases = [
    RoundTripCase(testDescription: "one tab",
                  session: Session(tabs: tabs(1), selectedIndex: 0, sidebarWidth: 220, collapsed: false)),
    RoundTripCase(testDescription: "3 tabs, the 2nd selected, sidebar collapsed",
                  session: Session(tabs: tabs(3), selectedIndex: 1, sidebarWidth: 180.5, collapsed: true)),
    RoundTripCase(testDescription: "a title with accents and an emoji", session: Session(
        tabs: [SessionTab(url: home, title: "tên có dấu 🎵 \"quoted\"")], selectedIndex: 0, sidebarWidth: 300,
        collapsed: false)),
    RoundTripCase(testDescription: "100 tabs, the last selected",
                  session: Session(tabs: tabs(100), selectedIndex: 99, sidebarWidth: 220, collapsed: false)),
]

/// What is saved is what comes back, and the save leaves only `session.json` (no temporary file).
@Test(arguments: roundTripCases)
func sessionRoundTrip(run: RoundTripCase) throws {
    try inFolder { folder in
        try SessionStore.save(run.session, in: folder)
        #expect(SessionStore.load(from: folder, home: home) == run.session)
        #expect(try FileManager.default.contentsOfDirectory(atPath: folder.path) == [SessionStore.fileName])
    }
}

private let futureSession = Session(tabs: tabs(2), selectedIndex: 0, sidebarWidth: 220, collapsed: false,
                                    version: Session.currentVersion + 1)

/// Files this build must not read: corrupt, or from a newer version (fields it does not know).
let badFiles: [(name: String, bytes: Data)] = [
    ("not JSON", Data("session".utf8)),
    ("an empty file", Data()),
    ("JSON cut short", Data("{\"version\": 1, \"tabs\": [".utf8)),
    ("JSON of another shape", Data("{\"tabs\": 3}".utf8)),
    ("a newer version", (try? JSONEncoder().encode(futureSession)) ?? Data()),
    ("a newer version with unknown fields only", Data("{\"version\": 99, \"windows\": []}".utf8)),
]

/// A bad file gives one home tab, and its bytes are kept as `session.bad.json`: no silent loss.
@Test(arguments: badFiles.map(\.name))
func badSessionFileGivesAHomeTabAndIsKept(name: String) throws {
    let bytes = try #require(badFiles.first { $0.name == name }?.bytes)
    try inFolder { folder in
        try bytes.write(to: folder.appendingPathComponent(SessionStore.fileName))
        #expect(SessionStore.load(from: folder, home: home) == Session.home(home))
        let kept = try? Data(contentsOf: folder.appendingPathComponent(SessionStore.badFileName))
        #expect(kept == bytes, "the bad file is kept as \(SessionStore.badFileName), byte for byte")
        #expect(!FileManager.default.fileExists(atPath: folder.appendingPathComponent(SessionStore.fileName).path))
    }
}

/// Nothing to restore (no file, or a saved session without tabs) gives one home tab.
@Test(arguments: [false, true])
func emptySessionGivesAHomeTab(savedWithoutTabs: Bool) throws {
    try inFolder { folder in
        if savedWithoutTabs {
            try SessionStore.save(Session(tabs: [], selectedIndex: 0, sidebarWidth: 220, collapsed: false), in: folder)
        }
        #expect(SessionStore.load(from: folder, home: home) == Session.home(home))
    }
}

@Test func homeSessionIsOneSelectedHomeTab() {
    let session = Session.home(home)
    #expect(session.tabs.map(\.url) == [home] && session.selectedIndex == 0)
    #expect(session.version == Session.currentVersion && !session.collapsed)
}
