import AppKit
import NhetrinhCore
import Testing
@testable import Nhetrinh

/// Put Tab to Idle / Put Other Tabs to Idle (headmate, 2026-11-19), red first: a row's menu sends tabs idle now,
/// as the idle timer does after its minutes. The tab in view is never idle: idling it moves the view to the
/// nearest other visible tab; Other Tabs keeps the tab clicked and shows it. The tree: _GroupsTests.swift.
@MainActor
struct IdleTabTests {
    private func loadedBrowser(selected: Int) -> BrowserWindowController {
        let browser = groupBrowser(selected: selected)
        browser.tabs.forEach { browser.load($0) }
        return browser
    }

    /// Wait (60 s at most) until `done` holds; WebKit answers "is it playing?" on the main queue.
    private func eventually(_ done: () -> Bool) async -> Bool {
        for _ in 0..<600 where !done() { try? await Task.sleep(nanoseconds: 100_000_000) }
        return done()
    }

    /// Row 9 is t6 (flat 5), row 0 is t1 (flat 0), row 2 is t2 (flat 1).
    @Test(arguments: [
        (0, 9, SidebarView.idleTab, 0, [true, true, true, true, true, false]),
        (0, 0, SidebarView.idleTab, 1, [false, true, true, true, true, true]),
        (5, 9, SidebarView.idleTab, 4, [true, true, true, true, true, false]),
        (0, 9, SidebarView.idleOtherTabs, 5, [false, false, false, false, false, true]),
        (5, 2, SidebarView.idleOtherTabs, 1, [false, true, false, false, false, false]),
    ] as [(Int, Int, String, Int, [Bool])])
    func theMenuSendsTabsIdle(selected: Int, row: Int, item: String, shown: Int, loaded: [Bool]) async {
        let browser = loadedBrowser(selected: selected)
        defer { browser.closeAfterTest() }
        #expect(browser.probeAnswer(.rowMenu(row: row, item: item), menu: nil) == .done)
        let idle = await eventually { browser.tabs.map(\.isLoaded) == loaded }
        #expect(idle, "loaded per tab: \(browser.tabs.map(\.isLoaded)), expected \(loaded)")
        #expect(browser.selected == shown && browser.tabs[shown].isLoaded)
    }

    /// The only tab cannot go idle: it is the one in view, and there is no other to show.
    @Test func theOnlyTabStaysLoaded() async {
        _ = NSApplication.shared
        let browser = BrowserWindowController()
        defer { browser.closeAfterTest() }
        browser.tabs = [Tab(url: URL(string: "about:blank?1"), title: "t1")]
        browser.select(0)
        #expect(browser.probeAnswer(.rowMenu(row: 0, item: SidebarView.idleTab), menu: nil) == .done)
        try? await Task.sleep(nanoseconds: 500_000_000)
        #expect(browser.selected == 0 && browser.tabs[0].isLoaded)
    }
}
