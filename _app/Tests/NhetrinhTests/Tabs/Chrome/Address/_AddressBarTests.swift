import AppKit
import NhetrinhCore
import Testing
import WebKit
@testable import Nhetrinh

/// P11-HISTORY wiring, on a store in a temporary folder only; no page loads (synthetic example.test addresses,
/// never selected, so no tab loads). A finished page is kept with the switch on, typed once when typed; the
/// switch off keeps nothing and the dropdown lists the open tabs only; the dropdown's keys; Clear All.
@MainActor
struct AddressBarTests {
    func browser() throws -> BrowserWindowController {
        _ = NSApplication.shared
        let browser = BrowserWindowController()
        let folder = try HistoryFolder.make()
        browser.keepHistory(in: folder, env: [:])
        browser.tabs = [Tab(url: nil), Tab(url: URL(string: "https://open.test/page"), title: "Open alpha page")]
        browser.selected = 0
        return browser
    }

    func kept(_ browser: BrowserWindowController, _ url: String) throws -> HistoryEntry? {
        try #require(browser.history.store).entry(url: url)
    }

    @Test func aFinishedPageIsKeptAndATypedOneOnce() throws {
        let browser = try browser()
        let tab = browser.tabs[0]
        browser.markTyped()
        browser.keepVisit(of: tab, url: URL(string: "https://example.test/a"), title: "Alpha", errorPage: false)
        browser.keepVisit(of: tab, url: URL(string: "https://example.test/a"), title: "Alpha", errorPage: false)
        let entry = try #require(try kept(browser, "https://example.test/a"))
        #expect(entry.visits == 2 && entry.typed == 1 && entry.title == "Alpha")
    }

    @Test(arguments: [(remember: false, errorPage: false), (remember: true, errorPage: true)])
    func theSwitchOffOrTheErrorPageKeepsNothing(remember: Bool, errorPage: Bool) throws {
        let browser = try browser()
        browser.prefs.rememberHistory = remember
        browser.keepVisit(of: browser.tabs[0], url: URL(string: "https://example.test/a"), title: "A",
                          errorPage: errorPage)
        #expect(try kept(browser, "https://example.test/a") == nil)
    }

    @Test(arguments: [true, false])
    func theDropdownListsHistoryOnlyWithTheSwitchOn(remember: Bool) throws {
        let browser = try browser()
        browser.keepVisit(of: browser.tabs[0], url: URL(string: "https://kept.test/"), title: "Kept alpha",
                          errorPage: false)
        browser.prefs.rememberHistory = remember
        browser.suggest(for: "alpha")
        let rows = browser.toolbar.suggestions.rows
        let expected = (remember ? ["https://kept.test/"] : []) + ["https://open.test/page"]
        #expect(rows.map(\.url) == expected)
        #expect(rows.last?.tab == 1)
        #expect(browser.toolbar.suggestions.shownRows.last?.hasSuffix("— Switch to tab") == true)
    }

    @Test func shiftDeleteRemovesTheChosenRowAndClearAllEmptiesTheStore() throws {
        let browser = try browser()
        for url in ["https://one.test/", "https://two.test/"] {
            browser.keepVisit(of: browser.tabs[0], url: URL(string: url), title: "row", errorPage: false)
        }
        browser.toolbar.address.stringValue = "row"
        browser.suggest(for: "row")
        let list = browser.toolbar.suggestions
        list.move(1)
        let removed = try #require(list.chosenRow)
        #expect(browser.toolbar.command(#selector(NSResponder.deleteBackward(_:)), shift: true))
        #expect(try kept(browser, removed.url) == nil)
        #expect(list.rows.count == 1)
        let hub = SettingsHub(store: .nonPersistent())
        browser.wire(hub)
        hub.clear(.all)
        #expect(try #require(browser.history.store).count == 0)
    }

    @Test func theHubSwitchSetsThePref() throws {
        let browser = try browser()
        let hub = SettingsHub(store: .nonPersistent())
        browser.wire(hub)
        #expect(hub.set(SettingsHub.historyTitle, to: "off"))
        #expect(!browser.prefs.rememberHistory)
        #expect(hub.keepHistory.state == .off)
        #expect(hub.set(SettingsHub.historyTitle, to: "on") && browser.prefs.rememberHistory)
    }

    @Test func noFolderNoStore() {
        _ = NSApplication.shared
        let browser = BrowserWindowController()
        browser.keepHistory(in: nil, env: [:])
        #expect(browser.history.store == nil)
    }
}

/// The keys of the dropdown, on the list alone: nothing chosen until ↓; Return opens the chosen row (none
/// chosen: the field's own action); Esc closes; ↑ past the first row chooses none; a closed list takes no key.
@MainActor
struct SuggestionKeysTests {
    private func toolbar(_ opened: @escaping (Suggestion) -> Void) -> ToolbarView {
        let toolbar = ToolbarView()
        toolbar.suggestions.onOpen = opened
        let rows = [Suggestion(url: "https://a.test/", title: "A", tab: nil),
                    Suggestion(url: "https://b.test/", title: "B", tab: 2)]
        toolbar.suggestions.show(rows, icons: [])
        return toolbar
    }

    @Test func returnOpensTheChosenRowOnly() {
        var opened: [String] = []
        let bar = toolbar { opened.append($0.url) }
        #expect(!bar.command(#selector(NSResponder.insertNewline(_:)), shift: false))
        #expect(opened.isEmpty && !bar.suggestions.isOpen)
        let again = toolbar { opened.append($0.url) }
        again.command(#selector(NSResponder.moveDown(_:)), shift: false)
        again.command(#selector(NSResponder.moveDown(_:)), shift: false)
        again.command(#selector(NSResponder.moveDown(_:)), shift: false)
        #expect(again.suggestions.chosen == 1)
        #expect(again.command(#selector(NSResponder.insertNewline(_:)), shift: false))
        #expect(opened == ["https://b.test/"] && !again.suggestions.isOpen)
    }

    @Test func upPastTheFirstRowChoosesNoneAndEscCloses() {
        let bar = toolbar { _ in }
        bar.command(#selector(NSResponder.moveDown(_:)), shift: false)
        bar.command(#selector(NSResponder.moveUp(_:)), shift: false)
        #expect(bar.suggestions.chosen == nil)
        #expect(bar.command(#selector(NSResponder.cancelOperation(_:)), shift: false))
        #expect(!bar.suggestions.isOpen)
        #expect(!bar.command(#selector(NSResponder.moveDown(_:)), shift: false))
    }

    @Test func aPlainDeleteIsTyping() {
        let bar = toolbar { _ in }
        bar.command(#selector(NSResponder.moveDown(_:)), shift: false)
        #expect(!bar.command(#selector(NSResponder.deleteBackward(_:)), shift: false))
    }
}

enum HistoryFolder {
    static func make() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("addressbar-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}
