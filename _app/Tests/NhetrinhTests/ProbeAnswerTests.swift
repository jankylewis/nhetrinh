import AppKit
import NhetrinhCore
import Testing
@testable import Nhetrinh

/// The probe acts as the user does (D23): through the menu item, the address field and the
/// sidebar table, never on the tabs directly. No app is launched: the controller is built here.
@MainActor
struct ProbeAnswerTests {
    private func browser(tabs titles: [String] = []) -> (BrowserWindowController, NSMenu) {
        _ = NSApplication.shared
        let browser = BrowserWindowController()
        browser.tabs = titles.map { Tab(url: nil, title: $0) }
        browser.refreshChrome()
        return (browser, AppMenu.build(browser: browser))
    }

    @Test(arguments: [
        ("File > New Tab", "⌘T"), ("File > Close Tab", "⌘W"), ("Tabs > Tab 9", "⌘9"), ("View > Reload", "⌘R"),
    ])
    func stateListsTheMenuShortcuts(path: String, shortcut: String) {
        let (browser, menu) = browser()
        #expect(browser.probeState(menu: menu).shortcuts[path] == shortcut)
    }

    @Test func stateShowsTheSidebarRows() {
        let (browser, menu) = browser(tabs: ["one", "two"])
        let state = browser.probeState(menu: menu)
        #expect(state.rows == ["one", "two"] && state.selected == nil)
    }

    @Test func newTabIsTheMenuItem() {
        let (browser, menu) = browser()
        #expect(browser.probeAnswer(.newTab, menu: menu) == .done)
        #expect(browser.probeState(menu: menu).rows == ["New Tab"])
        #expect(browser.probeAnswer(.closeTab, menu: menu) == .done)
        #expect(browser.tabs.isEmpty)
    }

    @Test(arguments: [ProbeRequest.newTab, .closeTab])
    func noMenuItemIsAFailureNotACrash(request: ProbeRequest) {
        let (browser, _) = browser()
        guard case .failed(let why) = browser.probeAnswer(request, menu: nil) else {
            Issue.record("a missing menu item was answered without a failure")
            return
        }
        #expect(why.hasPrefix("no menu item File > "))
    }

    @Test func navigateSubmitsTheAddressField() {
        let (browser, menu) = browser(tabs: ["one"])
        var submitted: String?
        browser.toolbar.onSubmit = { submitted = $0 }
        #expect(browser.probeAnswer(.navigate("rock & roll"), menu: menu) == .done)
        #expect(submitted == "rock & roll")
    }

    @Test(arguments: [0, 1])
    func selectIsAClickOnTheRow(row: Int) {
        let (browser, menu) = browser(tabs: ["one", "two"])
        #expect(browser.probeAnswer(.select(row), menu: menu) == .done)
        #expect(browser.selected == row)
        #expect(browser.probeState(menu: menu).selected == row)
    }

    @Test(arguments: [2, 9])
    func selectOutsideTheRowsFails(row: Int) {
        let (browser, menu) = browser(tabs: ["one", "two"])
        #expect(browser.probeAnswer(.select(row), menu: menu) == .failed("the sidebar has no row \(row)"))
    }

    /// P8-MIN-1: Minimize goes through the Window menu's own item; an unknown item or no menu fails.
    @Test(arguments: [
        ("Minimize", false, "no menu item Window > Minimize"), ("Close", true, "no menu item Window > Close"),
    ])
    func windowRequestNeedsItsMenuItem(item: String, withMenu: Bool, why: String) {
        let (browser, menu) = browser()
        #expect(browser.probeAnswer(.window(item), menu: withMenu ? menu : nil) == .failed(why))
    }
}
