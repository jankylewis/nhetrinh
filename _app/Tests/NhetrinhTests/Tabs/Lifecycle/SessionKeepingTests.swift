import AppKit
import NhetrinhCore
import Testing
@testable import Nhetrinh

/// P1 wiring that needs no running app: restore shows every row and loads only the selected tab;
/// what is saved is what was restored; the session folder follows the launch environment.
/// `restore` is called directly: no session file is read or written here.
@MainActor
struct SessionKeepingTests {
    private func session(selected: Int) -> Session {
        let tabs = (1...3).compactMap { index in
            URL(string: "about:blank#\(index)").map { SessionTab(url: $0, title: "Tab \(index)") }
        }
        return Session(tabs: tabs, selectedIndex: selected, sidebarWidth: 220, collapsed: false)
    }

    private func restored(_ session: Session) -> BrowserWindowController {
        _ = NSApplication.shared
        let browser = BrowserWindowController()
        browser.restore(TreeSession(migrating: session))  // P7: a version 1 session, migrated
        return browser
    }

    @Test(arguments: [0, 1, 2])
    func restoreLoadsOnlyTheSelectedTab(selected: Int) {
        let browser = restored(session(selected: selected))
        let state = browser.probeState(menu: nil)
        #expect(state.rows == ["Tab 1", "Tab 2", "Tab 3"] && state.selected == selected)
        #expect(state.loaded == (0..<3).map { $0 == selected })
    }

    @Test(arguments: [0, 2])
    func whatIsSavedIsWhatWasRestored(selected: Int) {
        let saved = session(selected: selected)
        let current = restored(saved).currentSession
        #expect(current.tree.allTabs == saved.tabs && current.selectedIndex == selected)
    }

    @Test func noSaveIsScheduledWithoutASessionFolder() {
        let browser = restored(session(selected: 1))
        #expect(browser.sessionFolder == nil && browser.saveTimer == nil)
    }

    @Test(arguments: [
        (env: ["NHT_BENCH_URLS": "https://example.com"], on: false, own: false),
        (env: [:], on: true, own: true),
        (env: ["NHT_PROFILE": "readback"], on: true, own: false),
    ])
    func sessionFolderFollowsTheLaunch(env: [String: String], on: Bool, own: Bool) {
        let folder = BrowserWindowController.sessionFolder(env)
        #expect((folder != nil) == on)
        #expect(folder.map { $0.lastPathComponent == "nhetrinh" } ?? false == own)
    }

    /// The probe's menu op finds the item now and performs it after the answer, so Quit can answer.
    /// Quit itself is not performed here: it would end the test process.
    @Test(arguments: [(path: ["Tabs", "Back"], done: true), (path: ["Tabs", "Sideways"], done: false)])
    func menuOpAnswersBeforeActing(path: [String], done: Bool) {
        let browser = restored(session(selected: 0))
        let menu = AppMenu.build(browser: browser)
        let answer = browser.probeAnswer(.menu(path), menu: menu)
        #expect((answer == .done) == done)
    }
}
