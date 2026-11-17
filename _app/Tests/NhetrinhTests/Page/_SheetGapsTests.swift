import AppKit
import Testing
import WebKit
@testable import Nhetrinh

/// P3-REVIEW: a page's sheet and the tab under it, red until the code is fixed. A sheet is window-modal:
/// it blocks the sidebar and the page, but the menu bar still reaches the window controller (⌘W, ⌃⇥).
/// No page loads from the network: every tab's page is `about:blank?<n>`.
@MainActor
struct SheetGapsTests {
    private func browser(_ count: Int, selected: Int) -> BrowserWindowController {
        _ = NSApplication.shared
        let browser = BrowserWindowController()
        browser.tabs = (1...count).map { Tab(url: URL(string: "about:blank?\($0)"), title: "t\($0)") }
        browser.selected = selected
        browser.load(browser.tabs[selected])
        browser.refreshChrome()
        return browser
    }

    /// The menu item at `path`, pressed as its key equivalent does: only when it validates.
    private func pressAsKey(_ path: [String], in menu: NSMenu, _ browser: BrowserWindowController) {
        let owner = path.dropLast().reduce(Optional(menu)) { $0?.item(withTitle: $1)?.submenu }
        guard let owner, let item = owner.item(withTitle: path.last ?? "") else {
            Issue.record("no menu item \(path)")
            return
        }
        if browser.validateMenuItem(item) { owner.performActionForItem(at: owner.index(of: item)) }
    }

    /// File > Close Tab (⌘W) while the selected page's `confirm` sheet is shown. Either the item is off
    /// while the sheet is up, or the sheet goes with its page and the page gets its answer. On 1d391d9 the
    /// tab closes and its sheet stays on the window, over the next tab's page, asking for a page that is gone.
    @Test(arguments: [["File", "Close Tab"], ["Tabs", "Select Next Tab"]])
    func aSheetNeverOutlivesOrHidesTheTabThatAsked(path: [String]) throws {
        let browser = browser(3, selected: 1)
        let menu = AppMenu.build(browser: browser)
        let asking = try #require(browser.tabs[1].webView)
        var answer: Int?
        let alert = NSAlert()
        alert.messageText = "127.0.0.1 says"
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        browser.ask(alert, for: asking) { answer = $0 }
        defer { browser.closeAfterTest() }
        try #require(browser.shownSheet != nil, "the sheet is shown on the window")
        pressAsKey(path, in: menu, browser)
        let stillShowsTheAsker = browser.tabs.indices.contains(browser.selected)
            && browser.tabs[browser.selected].webView === asking
        let sheetGone = browser.shownSheet == nil
        let shown = browser.tabs[browser.selected].title
        let seen = "after \(path.joined(separator: " > ")): the selected tab is \(shown), "
            + "the sheet is \(sheetGone ? "gone" : "still shown"), the answer \(answer.map(String.init) ?? "none")"
        #expect(stillShowsTheAsker || (sheetGone && answer != nil), "\(seen)")
        if let sheet = browser.shownSheet, let window = browser.window {
            Screen.presenter.end(sheet, on: window, .abort)
        }
    }
}

/// P8-TESTWIN-1: a unit test never shows a window on the headmate's screen. The paths that did (a sheet on the
/// browser window, the Settings Hub and its Clear sheet) are taken here and read as shown; then no window of
/// this process is visible, nor one a test that ran before left visible.
@MainActor
struct NoWindowOnScreenTests {
    @Test func noTestWindowIsEverVisible() throws {
        _ = NSApplication.shared
        let browser = BrowserWindowController()
        defer { browser.closeAfterTest() }
        let alert = NSAlert()
        alert.addButton(withTitle: "OK")
        var answer: Int?
        browser.ask(alert, for: nil) { answer = $0 }
        browser.showSettingsHub(nil)
        let hub = try #require(browser.hub)
        defer { hub.close() }
        hub.askToClear()
        let hubSheet = try #require(hub.window.flatMap { Screen.presenter.sheet(on: $0) }, "the Clear sheet is held")
        #expect(browser.shownSheet === alert.window && browser.probeState(menu: nil).hubShown)
        let visible = NSApp.windows.filter(\.isVisible).map { "\($0.className) \($0.title)" }
        #expect(visible.isEmpty, "windows on screen: \(visible)")
        alert.buttons[0].performClick(nil)
        #expect(answer == 0 && browser.shownSheet === hubSheet, "a held sheet's button answers it")
        if let window = hub.window { Screen.presenter.end(hubSheet, on: window, .cancel) }
    }
}

extension BrowserWindowController {
    /// P8-TESTWIN-1: a test's browser window ends closed. A window made in code is released by AppKit when it
    /// closes, while ARC still holds it: kept instead.
    func closeAfterTest() {
        window?.isReleasedWhenClosed = false
        close()
    }
}
