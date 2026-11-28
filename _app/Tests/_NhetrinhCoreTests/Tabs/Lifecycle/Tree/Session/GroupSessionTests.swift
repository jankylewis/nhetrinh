import Foundation
import Testing
@testable import NhetrinhCore

// P8-GROUPS-1, red first: session version 3 keeps nested groups; version 2 and version 1 are read as before
// (_TreeSessionTests.swift); a file deeper than `GroupDepth.max` is bad.

private let home = URL(string: "https://www.google.com") ?? URL(fileURLWithPath: "/")

private func nested(_ name: String, collapsed: Bool = false, _ items: TabTree.Item...) -> TabTree.Item {
    .folder(TabFolder(name: name, collapsed: collapsed, items: items))
}

/// a | Work (b | FE, collapsed (c)); c selected: the fixture `v3Nested`.
private let work = TreeSession(
    tree: TabTree(items: [treeRoot("a"), nested("Work", treeRoot("b"), nested("FE", collapsed: true, treeRoot("c")))]),
    selected: TabPath([1, 1, 0]), sidebarWidth: 220, collapsed: false)

/// The headmate's 4 levels, a tab at each, the deepest selected.
private let fourLevels = TreeSession(
    tree: TabTree(items: [nested("Work", treeRoot("b"), nested("FE", treeRoot("c"), nested(
        "PRs", collapsed: true, treeRoot("d"), nested("Feedback entry", treeRoot("Thumbnail")))))]),
    selected: TabPath([0, 1, 1, 1, 0]), sidebarWidth: 260, collapsed: false)

@Test func versionThreeIsWrittenAsTheFixture() throws {
    let written = try TreeSessionStore.encode(work)
    #expect(String(decoding: written, as: UTF8.self) == SessionFixtures.v3Nested)
    #expect(TreeSessionStore.decode(Data(SessionFixtures.v3Nested.utf8)) == work)
}

/// What is saved is what comes back, at every depth; the selection's path too.
@Test(arguments: [work, fourLevels])
func versionThreeRoundTrip(session: TreeSession) throws {
    let folder = FileManager.default.temporaryDirectory.appendingPathComponent("nhetrinh-groups-\(UUID())")
    defer { try? FileManager.default.removeItem(at: folder) }
    try TreeSessionStore.save(session, in: folder)
    let loaded = TreeSessionStore.load(from: folder, home: home)
    #expect(loaded == session && loaded.tree.depth == session.tree.depth)
    #expect(loaded.selectedIndex == session.tree.allTabs.count - 1)
}

/// A version 2 file reads as one level; its paths ({"item","tab"}) are the same paths.
@Test func versionTwoPathsAreTheSamePaths() throws {
    let session = try #require(TreeSessionStore.decode(Data(SessionFixtures.v2Folders.utf8)))
    #expect(session.selected == TabPath([1, 1]) && session.tree.depth == 1)
    #expect(session.tree.allTabs.map(\.title) == ["a", "b", "c", "d"])
}

/// 4 levels are read; 5 are not (the file is bad: one home tab, its bytes kept).
@Test(arguments: [(SessionFixtures.v3FiveLevels, false), (String(decoding: (try? TreeSessionStore.encode(fourLevels))
    ?? Data(), as: UTF8.self), true)])
func versionThreeDepthIsChecked(text: String, read: Bool) {
    #expect((TreeSessionStore.decode(Data(text.utf8)) != nil) == read)
}
