import Foundation
import Testing
@testable import NhetrinhCore

/// P11-HISTORY (D30): `history.sqlite` in the folder it is given, one row per page: visits, typed, last visit,
/// title; the cap drops the lowest score; remove and clear; the file is the user's alone (0600).
struct HistoryStoreTests {
    @Test func aVisitCountsAndATypedVisitCountsTwice() throws {
        let store = try HistoryRig.store()
        try HistoryRig.visit(store, "https://example.test/a", title: "A page", times: 3, timing: (typed: 1, days: 2))
        let entry = try #require(try store.entry(url: "https://example.test/a"))
        #expect(entry.visits == 3)
        #expect(entry.typed == 1)
        #expect(entry.title == "A page")
        #expect(entry.lastVisit == HistoryRig.daysAgo(2))
        #expect(store.count == 1)
    }

    @Test func aLaterVisitWithoutATitleKeepsTheTitleAndTheLatestDate() throws {
        let store = try HistoryRig.store()
        try store.record(url: "https://example.test/", title: "Kept", typed: false, at: HistoryRig.daysAgo(1))
        try store.record(url: "https://example.test/", title: "", typed: false, at: HistoryRig.daysAgo(3))
        let entry = try #require(try store.entry(url: "https://example.test/"))
        #expect(entry.title == "Kept")
        #expect(entry.lastVisit == HistoryRig.daysAgo(1))
        #expect(try HistoryRig.urls(store, "kept") == ["https://example.test/"])
    }

    @Test func theFileIsHistorySqliteAndOnlyTheUsers() throws {
        let store = try HistoryRig.store()
        try HistoryRig.visit(store, "https://example.test/")
        #expect(store.fileURL.lastPathComponent == "history.sqlite")
        let mode = try FileManager.default.attributesOfItem(atPath: store.fileURL.path)[.posixPermissions] as? Int
        #expect(mode == 0o600)
    }

    @Test func aFileMadeWithWiderRightsIsNarrowedAtOpen() throws {
        let folder = try HistoryRig.folder()
        let file = folder.appendingPathComponent(HistoryStore.fileName)
        let created = FileManager.default.createFile(atPath: file.path, contents: nil,
                                                      attributes: [.posixPermissions: 0o644])
        #expect(created)
        _ = try HistoryStore(folder: folder)
        #expect(try FileManager.default.attributesOfItem(atPath: file.path)[.posixPermissions] as? Int == 0o600)
    }

    @Test func theHistoryIsThereAfterAReopen() throws {
        let folder = try HistoryRig.folder()
        try HistoryRig.visit(try HistoryStore(folder: folder), "https://example.test/kept", title: "Kept")
        #expect(try HistoryStore(folder: folder).entry(url: "https://example.test/kept")?.title == "Kept")
    }

    /// Sign-in steps kept before the rule (headmate, 2026-11-19) go when the store opens; other pages stay.
    @Test func signInStepsKeptBeforeGoAtTheNextOpen() throws {
        let folder = try HistoryRig.folder()
        let step = "https://id.example.test/authorize?client_id=a&response_type=code"
        try HistoryRig.visit(try HistoryStore(folder: folder), step, title: "Sign in")
        try HistoryRig.visit(try HistoryStore(folder: folder), "https://example.test/kept", title: "Kept")
        let reopened = try HistoryStore(folder: folder)
        #expect(try reopened.entry(url: step) == nil && reopened.count == 1)
    }

    @Test func removeTakesOnlyThatPage() throws {
        let store = try HistoryRig.store()
        try HistoryRig.visit(store, "https://example.test/one", title: "one")
        try HistoryRig.visit(store, "https://example.test/two", title: "two")
        try store.remove(url: "https://example.test/one")
        #expect(try HistoryRig.urls(store, "example") == ["https://example.test/two"])
    }

    @Test func clearTakesEveryPage() throws {
        let store = try HistoryRig.store()
        try HistoryRig.visit(store, "https://example.test/one")
        try HistoryRig.visit(store, "https://other.test/two")
        try store.clear()
        #expect(store.count == 0)
        #expect(try HistoryRig.urls(store, "test").isEmpty)
    }

    /// Past the cap the lowest score goes: the old page visited once, not the fresh one or the often visited one.
    @Test(arguments: [3, 4])
    func theCapDropsTheLowestScore(capacity: Int) throws {
        let store = try HistoryRig.store(capacity: capacity)
        try HistoryRig.visit(store, "https://often.test/", times: 5, timing: (typed: 0, days: 100))
        try HistoryRig.visit(store, "https://old.test/", timing: (typed: 0, days: 100))
        try HistoryRig.visit(store, "https://fresh.test/", timing: (typed: 0, days: 1))
        try HistoryRig.visit(store, "https://typed.test/", timing: (typed: 1, days: 50))
        try HistoryRig.visit(store, "https://new.test/", timing: (typed: 0, days: 0))
        #expect(store.count == capacity)
        #expect(try store.entry(url: "https://old.test/") == nil)
        #expect(try store.entry(url: "https://new.test/") != nil)
        #expect(try store.entry(url: "https://fresh.test/") != nil)
        #expect(try (store.entry(url: "https://often.test/") != nil) == (capacity == 4))
    }

    @Test func theCapIsFiveThousandAndEightRowsAreShown() {
        #expect(HistoryStore.capacity == 5_000)
        #expect(HistoryStore.shown == 8)
    }

    @Test func atMostEightSuggestions() throws {
        let store = try HistoryRig.store()
        for index in 0..<12 { try HistoryRig.visit(store, "https://example.test/\(index)") }
        #expect(try store.suggestions(for: "example", now: HistoryRig.now).count == 8)
    }

    @Test(arguments: ["", "   "])
    func nothingTypedSuggestsNothing(typed: String) throws {
        let store = try HistoryRig.store()
        try HistoryRig.visit(store, "https://example.test/")
        #expect(try HistoryRig.urls(store, typed).isEmpty)
    }

    /// SQL's own wildcards and quotes are plain text to the match.
    @Test(arguments: ["%", "_", "'", "a%b"])
    func wildcardsAreText(typed: String) throws {
        let store = try HistoryRig.store()
        try HistoryRig.visit(store, "https://example.test/", title: "plain")
        #expect(try HistoryRig.urls(store, typed).isEmpty)
    }
}
