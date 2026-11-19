import Foundation
import Testing
@testable import NhetrinhCore

/// P10-PROFILE (D29): P9's layout to one folder per profile. Every case of the brief: each file moved, a target
/// kept, a crash in the middle finished by the next run, a second run a no-op, a failure leaving P9's files.
@Test func defaultsRootFilesMoveIntoDefault() throws {
    let rig = MigrationRig()
    for name in ProfileMigration.rootFiles { try rig.put(name, "old \(name)") }
    try rig.put("readback/session.json", "readback's")
    let outcome = ProfileMigration.run(rig.layout())
    let moved = ProfileMigration.rootFiles.count
    #expect(outcome == .init(folder: rig.layout().folder, moved: moved, kept: 0, failure: nil))
    for name in ProfileMigration.rootFiles {
        #expect(rig.read("Default/\(name)") == "old \(name)" && !rig.exists(name))
    }
    #expect(rig.read("readback/session.json") == "readback's", "another profile's folder is not touched")
}

@Test func theTabsReadAfterTheMoveAreP9s() throws {
    let rig = MigrationRig()
    let home = try #require(URL(string: "about:blank"))
    let page = try #require(URL(string: "https://example.com/kept"))
    let session = Session(tabs: [SessionTab(url: page, title: "Kept")], selectedIndex: 0, sidebarWidth: 220,
                          collapsed: false)
    try SessionStore.save(session, in: rig.root)
    let outcome = ProfileMigration.run(rig.layout())
    #expect(TreeSessionStore.load(from: outcome.folder, home: home).tree.allTabs.map(\.url) == [page])
}

@Test func aTargetThatExistsIsKeptAndItsSourceLeft() throws {
    let rig = MigrationRig()
    try rig.put("session.json", "root")
    try rig.put("prefs.json", "root prefs")
    try rig.put("Default/session.json", "target")
    let outcome = ProfileMigration.run(rig.layout())
    #expect(outcome.moved == 1 && outcome.kept == 1 && outcome.failure == nil)
    #expect(rig.read("Default/session.json") == "target" && rig.read("session.json") == "root")
    #expect(outcome.line == "profile: migrated 1, kept 1 (target exists)", "counts only, no path")
}

/// A crash after the first moves: the next run moves the rest; a third run moves nothing.
@Test func aCrashInTheMiddleIsFinishedAndASecondRunIsANoOp() throws {
    let rig = MigrationRig()
    try rig.put("Default/session.json", "moved before the crash")
    try rig.put("prefs.json", "still at the root")
    try rig.put("running.marker", "")
    let first = ProfileMigration.run(rig.layout())
    #expect(first.moved == 2 && first.kept == 0 && first.failure == nil)
    #expect(rig.read("Default/prefs.json") == "still at the root" && rig.exists("Default/running.marker"))
    let second = ProfileMigration.run(rig.layout())
    #expect(second == .init(folder: rig.layout().folder, moved: 0, kept: 0, failure: nil))
}

@Test func nothingToMoveMakesNoFolder() throws {
    let rig = MigrationRig()
    let outcome = ProfileMigration.run(rig.layout())
    #expect(outcome.folder == rig.layout().folder && outcome.moved == 0 && !rig.exists("Default"))
}

/// A move fails: this run's moves are put back, the launch reads P9's root, every old file is readable there.
@Test(arguments: [1, 2, 3])
func aFailedMoveLeavesP9sFilesAndTheOldFolder(failAt: Int) throws {
    let rig = MigrationRig()
    for name in ["session.json", "prefs.json", "running.marker"] { try rig.put(name, "old \(name)") }
    let (move, _) = MigrationRig.failing(at: failAt)
    let outcome = ProfileMigration.run(rig.layout(), move: move)
    #expect(outcome.failure != nil && outcome.folder == rig.layout().legacyFolder)
    for name in ["session.json", "prefs.json", "running.marker"] {
        #expect(rig.read(name) == "old \(name)" && !rig.exists("Default/\(name)"))
    }
    let again = ProfileMigration.run(rig.layout())
    #expect(again.moved == 3 && again.failure == nil, "the next launch migrates")
}

/// P9's crash marker moves with the session: a clean P9 quit (no marker) stays clean, a P9 crash stays one.
@Test(arguments: [true, false])
func theCleanQuitMarkerKeepsItsMeaning(crashed: Bool) throws {
    let rig = MigrationRig()
    try rig.put("session.json")
    if crashed { try rig.put("running.marker", "") }
    let outcome = ProfileMigration.run(rig.layout())
    #expect(try CleanQuitMarker(folder: outcome.folder).launch() == crashed)
}

@Test func aNamedProfilesOldFolderIsRenamed() throws {
    let rig = MigrationRig()
    let id = Profile.identifier(for: "readback").uuidString
    try rig.put("profiles/\(id)/session.json", "readback's")
    try rig.put("profiles/\(Profile.identifier(for: "other").uuidString)/session.json", "other's")
    try rig.put("session.json", "Default's, at the root")
    let outcome = ProfileMigration.run(rig.layout("readback"))
    #expect(outcome == .init(folder: rig.layout("readback").folder, moved: 1, kept: 0, failure: nil))
    #expect(rig.read("readback/session.json") == "readback's" && !rig.exists("profiles/\(id)"))
    #expect(rig.read("session.json") == "Default's, at the root", "a named profile never moves Default's files")
    #expect(ProfileMigration.run(rig.layout("readback")).moved == 0, "a second run: nothing")
}

@Test func aNamedProfilesTargetIsKeptAndAFailureUsesTheOldFolder() throws {
    let rig = MigrationRig()
    let id = Profile.identifier(for: "work").uuidString
    try rig.put("profiles/\(id)/session.json", "old")
    let (move, _) = MigrationRig.failing(at: 1)
    let failed = ProfileMigration.run(rig.layout("work"), move: move)
    #expect(failed.failure != nil && failed.folder == rig.layout("work").legacyFolder)
    #expect(rig.read("profiles/\(id)/session.json") == "old")
    try rig.put("work/session.json", "new")
    let kept = ProfileMigration.run(rig.layout("work"))
    #expect(kept.kept == 1 && kept.moved == 0 && rig.read("profiles/\(id)/session.json") == "old")
}

/// P11's history (D30) lives at the root until P10 too, with SQLite's two side files: it moves with the session,
/// or the address bar forgets every visited page at the first launch of a build holding both (review, 2026-11-19).
@Test(arguments: ["history.sqlite", "history.sqlite-wal", "history.sqlite-shm"])
func p11sHistoryMovesIntoDefault(name: String) throws {
    let rig = MigrationRig()
    try rig.put(name, "pages")
    _ = ProfileMigration.run(rig.layout())
    #expect(rig.read("Default/\(name)") == "pages" && !rig.exists(name))
}
