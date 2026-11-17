import Foundation
import Testing
@testable import NhetrinhCore

// P7 session schema version 2 and the migration from version 1, red first on stubs (P7-PREP-1, D24).

private let home = URL(string: "https://www.google.com") ?? URL(fileURLWithPath: "/")
private let file = SessionStore.fileName

/// A new empty folder per test (the tests run in parallel), removed afterwards.
private func inFolder(_ body: (URL) throws -> Void) throws {
    let folder = FileManager.default.temporaryDirectory.appendingPathComponent("nhetrinh-tree-\(UUID())")
    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: folder) }
    try body(folder)
}

private func roots(_ names: [String]) -> TabTree { TabTree(items: names.map(treeRoot)) }

/// Version 1: the flat list becomes root tabs in order; selection (clamped), width and collapsed are kept.
@Test(arguments: [
    (SessionFixtures.v1ThreeTabs, TreeSession(tree: roots(["a", "b", "c"]), selected: TabPath(item: 1),
                                              sidebarWidth: 240.5, collapsed: true)),
    (SessionFixtures.v1SelectedPastTheEnd, TreeSession(tree: roots(["a", "b"]), selected: TabPath(item: 1),
                                                       sidebarWidth: 220, collapsed: false)),
])
func versionOneIsMigrated(text: String, expected: TreeSession) throws {
    let v1 = try #require(SessionStore.decode(Data(text.utf8)), "the fixture is a version 1 file P1 reads")
    #expect(TreeSession(migrating: v1.clamped) == expected)
    #expect(TreeSessionStore.decode(Data(text.utf8)) == expected)
}

/// Loading a version 1 file keeps its bytes once as `session.v1.json`; a backup already there is never
/// replaced (a second version 1 file, after a downgrade, does not overwrite the first).
@Test(arguments: [false, true])
func versionOneIsKeptOnceAsABackup(backupThere: Bool) throws {
    try inFolder { folder in
        let backup = folder.appendingPathComponent(TreeSessionStore.backupFileName)
        let older = Data("an older backup".utf8)
        if backupThere { try older.write(to: backup) }
        let bytes = Data(SessionFixtures.v1ThreeTabs.utf8)
        try bytes.write(to: folder.appendingPathComponent(file))
        let loaded = TreeSessionStore.load(from: folder, home: home)
        #expect(loaded.tree == roots(["a", "b", "c"]) && loaded.selected == TabPath(item: 1))
        #expect(try Data(contentsOf: backup) == (backupThere ? older : bytes))
    }
}

@Test func versionTwoFixtureIsRead() {
    let tree = TabTree(items: [treeRoot("a"), treeFolder("work", ["b", "c"], collapsed: true), treeRoot("d")])
    let expected = TreeSession(tree: tree, selected: TabPath(item: 1, tab: 1), sidebarWidth: 220, collapsed: false)
    #expect(TreeSessionStore.decode(Data(SessionFixtures.v2Folders.utf8)) == expected)
}

let treeRoundTrips: [(String, TreeSession)] = [
    ("root tabs only", TreeSession(tree: roots(["a", "b"]), selected: TabPath(item: 1), sidebarWidth: 220,
                                   collapsed: false)),
    ("a collapsed folder, its 2nd tab selected", TreeSession(tree: sampleTree(collapsed: true),
                                                             selected: TabPath(item: 1, tab: 1), sidebarWidth: 300,
                                                             collapsed: true)),
    ("an empty folder and a title with accents", TreeSession(
        tree: TabTree(items: [treeFolder("trống", []), .tab(SessionTab(url: home, title: "tên có dấu 🎵 \"q\""))]),
        selected: TabPath(item: 1), sidebarWidth: 180.5, collapsed: false)),
]

/// What is saved is what comes back, and the save leaves only `session.json`.
@Test(arguments: treeRoundTrips.map(\.0))
func versionTwoRoundTrip(name: String) throws {
    let session = try #require(treeRoundTrips.first { $0.0 == name }?.1)
    try inFolder { folder in
        try TreeSessionStore.save(session, in: folder)
        #expect(TreeSessionStore.load(from: folder, home: home) == session)
        #expect(try FileManager.default.contentsOfDirectory(atPath: folder.path) == [file])
    }
}

/// A file version 2 refuses gives one home tab, and its bytes are kept as `session.bad.json`.
@Test(arguments: SessionFixtures.bad.map(\.name))
func badVersionTwoFileGivesAHomeTabAndIsKept(name: String) throws {
    let bytes = try #require(SessionFixtures.bad.first { $0.name == name }.map { Data($0.text.utf8) })
    try inFolder { folder in
        try bytes.write(to: folder.appendingPathComponent(file))
        #expect(TreeSessionStore.decode(bytes) == nil)
        #expect(TreeSessionStore.load(from: folder, home: home).tree.allTabs.map(\.url) == [home])
        #expect((try? Data(contentsOf: folder.appendingPathComponent(SessionStore.badFileName))) == bytes)
    }
}

/// Nothing to restore, or a version 1 file without tabs: one home tab at the root, selected.
@Test(arguments: [false, true])
func nothingToRestoreGivesAHomeTab(v1WithoutTabs: Bool) throws {
    try inFolder { folder in
        if v1WithoutTabs { try Data(SessionFixtures.v1NoTabs.utf8).write(to: folder.appendingPathComponent(file)) }
        let loaded = TreeSessionStore.load(from: folder, home: home)
        #expect(loaded.tree.items == [.tab(SessionTab(url: home, title: "www.google.com"))])
        #expect(loaded.selected == TabPath(item: 0) && TreeSession.version == 3)
    }
}

/// P7-FIX-1 (REVIEW_P7 P3 ruling), red first: a session of folders and no tab (the last tab closed, the
/// app quit) keeps its folders, with one home tab at the root's end, selected.
@Test func foldersWithoutATabAreKept() throws {
    try inFolder { folder in
        let empty = TreeSession(tree: TabTree(items: [.folder(TabFolder(name: "work", collapsed: true))]),
                                selected: TabPath(item: 0), sidebarWidth: 220, collapsed: false)
        try TreeSessionStore.save(empty, in: folder)
        let loaded = TreeSessionStore.load(from: folder, home: home)
        let homeTab = SessionTab(url: home, title: "www.google.com")
        #expect(loaded.tree.items == [.folder(TabFolder(name: "work", collapsed: true)), .tab(homeTab)])
        #expect(loaded.selected == TabPath(item: 1))
    }
}
