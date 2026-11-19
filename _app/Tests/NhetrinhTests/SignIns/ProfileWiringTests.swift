import AppKit
import NhetrinhCore
import Testing
@testable import Nhetrinh

/// P10-PROFILE (D29) wiring, under this process's temporary root only (`DataRoot` before a launch): no test
/// reaches the real Application Support, a Keychain or a WebKit store. Each test uses a profile of its own.
@MainActor
struct ProfileWiringTests {
    let name = "wiring-\(UUID().uuidString.prefix(8))"
    var env: [String: String] { ["NHT_PROFILE": name] }

    /// `folders` removed, then the temporary root's own folders while they are empty (`rmdir` keeps a full one).
    private func clean(_ folders: [URL]) {
        folders.forEach { try? FileManager.default.removeItem(at: $0) }
        let root = DataRoot.support.appendingPathComponent(ProfileLayout.appFolder)
        for folder in [root.appendingPathComponent(ProfileLayout.legacyProfiles), root, DataRoot.support] {
            rmdir(folder.path)
        }
    }

    /// Guard: before a launch the root is a temporary folder, never `~/Library/Application Support`.
    @Test func noTestReachesTheRealApplicationSupport() throws {
        let real = try #require(FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first)
        #expect(!DataRoot.support.standardizedFileURL.path.hasPrefix(real.standardizedFileURL.path))
        #expect(DataRoot.support.path.hasPrefix(FileManager.default.temporaryDirectory.path))
        for env in [[:], ["NHT_PROFILE": "readback"]] {
            let folder = try #require(BrowserWindowController.sessionFolder(env))
            #expect(folder.path.hasPrefix(DataRoot.support.path) && !folder.path.hasPrefix(real.path))
        }
    }

    /// HARD RULE: no NHT_PROFILE is Default on WebKit's default store; readback its own; a refused name nothing.
    @Test(arguments: [(env: [:], store: "default"), (["NHT_PROFILE": ""], "default"),
                      (["NHT_PROFILE": "readback"], "id 75CF0542-34C3-8753-0F42-CCD2A84A40A2"),
                      (["NHT_PROFILE": "Default"], "none"), (["NHT_PROFILE": "default"], "none")])
    func theStoreFollowsTheProfile(env: [String: String], store: String) {
        let layout = BrowserWindowController.profileLayout(env)
        let chosen = WebConfig.choose(layout?.webStore, standard: { "default" }, none: { "none" },
                                      identified: { "id \($0.uuidString)" })
        #expect(chosen == store)
    }

    @Test(arguments: ["Default", "DEFAULT", "a/b"])
    func aRefusedNameKeepsNoFolder(profile: String) {
        #expect(BrowserWindowController.sessionFolder(["NHT_PROFILE": profile]) == nil)
        #expect(BrowserWindowController.prepareProfile(["NHT_PROFILE": profile]) == nil)
    }

    @Test func theLaunchMigratesAndWritesProfileJSON() throws {
        let layout = try #require(BrowserWindowController.profileLayout(env))
        defer { clean([layout.folder]) }
        let legacy = layout.legacyFolder
        try FileManager.default.createDirectory(at: legacy, withIntermediateDirectories: true)
        try Data("old".utf8).write(to: legacy.appendingPathComponent("session.json"))
        let folder = BrowserWindowController.prepareProfile(env)
        #expect(folder == layout.folder && !FileManager.default.fileExists(atPath: legacy.path))
        #expect(ProfileInfo.read(from: layout.folder) == layout.info)
        #expect(BrowserWindowController.prepareProfile(["NHT_BENCH_URLS": "https://example.com"]) == nil)
    }

    /// Reset: this profile's files and Keychain item go, another profile's stay; one home tab after.
    @Test func resetEmptiesThisProfileOnly() throws {
        let layout = try #require(BrowserWindowController.profileLayout(env))
        let other = try #require(BrowserWindowController.profileLayout(["NHT_PROFILE": name + "-other"]))
        defer { clean([layout.folder, other.folder]) }
        for (folder, file) in [(layout.folder, "prefs.json"), (layout.folder, "session.json"), (other.folder, "x")] {
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            try Data("x".utf8).write(to: folder.appendingPathComponent(file))
        }
        let secrets = HeldSecrets()
        secrets.items = [layout.keychainService: Data("a".utf8), other.keychainService: Data("b".utf8)]
        _ = NSApplication.shared
        let browser = BrowserWindowController()
        defer { browser.closeAfterTest() }
        browser.sessionFolder = layout.folder
        browser.signIns = SignInKeeper(secrets: secrets, jar: HeldJar(), marker: CleanQuitMarker(folder: layout.folder),
                                       service: layout.keychainService) { _ in }
        var done = false
        browser.resetProfile(env: env, home: URL(string: "about:blank")) { done = true }
        #expect(done && browser.tabs.count == 1)
        #expect(Set(secrets.items.keys) == [other.keychainService], "only this profile's item is deleted")
        let left = try FileManager.default.contentsOfDirectory(atPath: layout.folder.path).sorted()
        #expect(left == ["session.json"], "the prefs gone (defaults are not written), the home tab saved")
        #expect(PrefsStore.load(from: layout.folder) == Prefs())
        #expect(FileManager.default.fileExists(atPath: other.folder.appendingPathComponent("x").path))
    }

    /// P10 with P11 (matemaster review, 2026-11-19): Reset empties the history too, and the next visit lands in a
    /// new file, never in the deleted one an open store would still hold (old rows shown until a relaunch).
    @Test func resetEmptiesTheHistoryAndKeepsRecording() throws {
        let layout = try #require(BrowserWindowController.profileLayout(env))
        defer { clean([layout.folder]) }
        _ = NSApplication.shared
        let browser = BrowserWindowController()
        defer { browser.closeAfterTest() }
        browser.sessionFolder = layout.folder
        browser.keepHistory(in: layout.folder, env: env)
        try browser.history.store?.record(url: "https://example.test/old", title: "Old", typed: false, at: Date())
        browser.resetProfile(env: env, home: URL(string: "about:blank"))
        #expect(browser.history.store?.count == 0)
        try browser.history.store?.record(url: "https://example.test/new", title: "New", typed: false, at: Date())
        #expect(try HistoryStore(folder: layout.folder).entry(url: "https://example.test/new") != nil)
    }

    /// The hub's sheet: Cancel (the default) does nothing; only Reset resets.
    @Test(arguments: [(button: 0, resets: false), (1, true)])
    func onlyResetResets(button: Int, resets: Bool) throws {
        let hub = SettingsHub(store: .nonPersistent())
        defer { hub.close() }
        var asked = false
        hub.onResetProfile = { asked = true }
        hub.askToReset()
        let sheet = try #require(hub.window.flatMap { Screen.presenter.sheet(on: $0) })
        let alertButtons = sheet.contentView.map(AppFont.controls(in:))?.compactMap { $0 as? NSButton } ?? []
        let pressed = try #require(alertButtons.first { $0.title == SettingsHub.resetButtons[button] })
        pressed.performClick(nil)
        #expect(asked == resets)
        #expect(SettingsHub.resetButtons == ["Cancel", "Reset"])
    }
}
