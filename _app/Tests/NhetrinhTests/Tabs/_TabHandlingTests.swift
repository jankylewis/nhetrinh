import AppKit
import NhetrinhCore
import Testing
@testable import Nhetrinh

/// P2 tab handling through the user's paths: the menu items, the row's menu, the toolbar button.
/// No app is launched and nothing goes to the network: every tab's page is `about:blank?<n>`.
@MainActor
struct TabHandlingTests {
    private func browser(_ count: Int, selected: Int) -> (BrowserWindowController, NSMenu) {
        _ = NSApplication.shared
        let browser = BrowserWindowController()
        browser.tabs = (1...count).map { Tab(url: page($0), title: "t\($0)") }
        browser.selected = selected
        browser.refreshChrome()
        return (browser, AppMenu.build(browser: browser))
    }

    /// Press a menu item as a click does, now (the probe's `.menu` waits for the next turn).
    private func press(_ path: [String], in menu: NSMenu) {
        let owner = path.dropLast().reduce(Optional(menu)) { $0?.item(withTitle: $1)?.submenu }
        let index = owner?.indexOfItem(withTitle: path.last ?? "") ?? -1
        #expect(index >= 0, "no menu item \(path)")
        if index >= 0 { owner?.performActionForItem(at: index) }
    }

    private func page(_ number: Int) -> URL? { URL(string: "about:blank?\(number)") }

    private func titles(_ browser: BrowserWindowController) -> [String] { browser.tabs.map(\.title) }

    @Test(arguments: [
        (2, ["Tabs", "Move Tab Up"], ["t1", "t3", "t2", "t4"], 1),
        (0, ["Tabs", "Move Tab Up"], ["t1", "t2", "t3", "t4"], 0),
        (1, ["Tabs", "Move Tab Down"], ["t1", "t3", "t2", "t4"], 2),
        (3, ["Tabs", "Move Tab Down"], ["t1", "t2", "t3", "t4"], 3),
    ])
    func moveTabKeepsItSelected(selected: Int, path: [String], expected: [String], after: Int) {
        let (browser, menu) = browser(4, selected: selected)
        press(path, in: menu)
        #expect(titles(browser) == expected && browser.selected == after)
        #expect(browser.probeState(menu: menu).selected == after)
    }

    @Test(arguments: [(0, 2), (1, 0), (2, 3)])
    func dragMoveFollowsTheSelection(from: Int, to: Int) {
        let (browser, _) = browser(4, selected: from)
        browser.sidebar.onMove?(from, to)
        #expect(browser.selected == to && browser.tabs[to].title == "t\(from + 1)")
    }

    @Test(arguments: [0, 1, 2])
    func rowMenuClosesThatRowAndReopenBringsItBack(row: Int) {
        let (browser, menu) = browser(3, selected: 2)
        #expect(browser.probeAnswer(.rowMenu(row: row, item: "Close Tab"), menu: menu) == .done)
        #expect(browser.tabs.count == 2 && !titles(browser).contains("t\(row + 1)"))
        #expect(browser.tabs[browser.selected].title == (row == 2 ? "t2" : "t3"), "the selected tab stays")
        press(["File", "Reopen Closed Tab"], in: menu)
        #expect(titles(browser) == ["t1", "t2", "t3"] && browser.selected == row)
        #expect(browser.tabs[row].url == page(row + 1))
    }

    @Test func rowMenuWithoutTheItemFails() {
        let (browser, menu) = browser(2, selected: 0)
        #expect(browser.probeAnswer(.rowMenu(row: 5, item: "Close Tab"), menu: menu) != .done)
        #expect(browser.probeAnswer(.rowMenu(row: 0, item: "Format Disk"), menu: menu) != .done)
        #expect(browser.tabs.count == 2)
    }

    @Test(arguments: [(0, [1, 8, 9, 2]), (1, [1, 2, 8, 9])])
    func backgroundTabsGoAfterTheSelectedOneInOrder(selected: Int, expected: [Int]) {
        let (browser, _) = browser(2, selected: selected)
        [8, 9].compactMap(page).forEach(browser.openInBackground)
        #expect(browser.tabs.map(\.url) == expected.map(page) && browser.selected == selected)
        #expect(browser.tabs.allSatisfy { !$0.isLoaded })
    }

    @Test(arguments: [(0, ["Tabs", "Select Next Tab"], 1), (2, ["Tabs", "Select Next Tab"], 0),
                      (0, ["Tabs", "Select Previous Tab"], 2)])
    func nextAndPreviousGoRoundTheEnd(selected: Int, path: [String], expected: Int) {
        let (browser, menu) = browser(3, selected: selected)
        press(path, in: menu)
        #expect(browser.selected == expected)
    }
}
