import AppKit
import NhetrinhCore
import Testing
@testable import Nhetrinh

/// P7-REVIEW (REVIEW_P7.md), red on p7/prep e0b91ff. Every tab is `about:blank` (no network); the
/// tree is written as root items: "r" a root tab, "A:a1,a2" folder A, "A*:a1" folder A collapsed.
@MainActor
struct FolderReviewTests {
    private func browser(_ spec: [String]) -> BrowserWindowController {
        _ = NSApplication.shared
        let browser = BrowserWindowController()
        func tab(_ title: String) -> Tab { Tab(url: URL(string: "about:blank"), title: title) }
        browser.tree = Tree(items: spec.map { item -> Tree<Tab>.Item in
            let parts = item.split(separator: ":", maxSplits: 1).map(String.init)
            guard parts.count == 2 else { return .tab(tab(item)) }
            let name = parts[0].replacingOccurrences(of: "*", with: "")
            return .folder(TreeFolder(name: name, collapsed: parts[0].hasSuffix("*"),
                                      tabs: parts[1].split(separator: ",").map { tab(String($0)) }))
        })
        return browser
    }

    private func shape(_ browser: BrowserWindowController) -> [String] {
        browser.tree.items.map { item in
            switch item {
            case .tab(let tab): return tab.title
            case .folder(let folder):
                let tabs = folder.allTabs.map(\.title).joined(separator: ",")
                return folder.name + (folder.collapsed ? "*" : "") + ":" + tabs
            }
        }
    }

    /// File > Reopen Closed Tab puts the tab back where it was. `ClosedTab` keeps only the flat index and
    /// `Tree.insert(atFlat:)` puts a tab after the tab before it, in that tab's folder, and at the end
    /// always at the root: a tab closed first in its folder, or a root tab right after a folder, comes back
    /// inside the folder above; the last tab of the last folder comes back at the root. The last case is
    /// the control (a middle tab of a folder: the tab before it is in the same folder).
    @Test(arguments: [
        (["A:a1", "B:b1,b2"], 1), (["A:a1", "r", "s"], 1), (["A:a1", "B:b1", "r"], 1), (["r", "A:a1,a2"], 2),
        (["r", "A:a1,a2,a3"], 2),
    ])
    func reopenPutsTheTabBackWhereItWas(spec: [String], close flat: Int) {
        let browser = browser(spec)
        browser.select(0)
        let before = shape(browser)
        browser.close(at: flat)
        browser.reopenClosedTab(nil)
        #expect(shape(browser) == before, "closed flat \(flat), reopened: \(shape(browser)), was \(before)")
        browser.tabs.forEach { $0.unload() }
    }

    /// Closing the selected tab selects a tab the user can see when there is one: today the next flat
    /// tab is chosen even when a collapsed folder hides it (r0 stays visible).
    @Test func closingTheSelectedTabSelectsAVisibleTab() {
        let browser = browser(["r0", "r1", "A*:a1"])
        browser.select(1)
        browser.close(at: 1)
        #expect(browser.tree.visibleFlatIndexes.contains(browser.selected),
                "selected flat \(browser.selected) (\(browser.tabs[browser.selected].title)), hidden in A")
        browser.tabs.forEach { $0.unload() }
    }

    /// P7-FIX-1 (P4): Move Tab Up / Down step one row in the container; a root tab passes a folder whole;
    /// at a folder's edge a tab steps out. The menu item is off when nothing would move.
    @Test(arguments: [
        (3, true, ["r", "s", "A:f1,f2"], "s"), (1, true, ["r", "f1", "A:f2", "s"], "f1"),
        (2, false, ["r", "A:f1", "f2", "s"], "f2"), (1, false, ["r", "A:f2,f1", "s"], "f1"),
    ])
    func moveTabStepsOneRow(selected: Int, up: Bool, expected: [String], title: String) {
        let browser = browser(["r", "A:f1,f2", "s"])
        browser.select(selected)
        up ? browser.moveTabUp(nil) : browser.moveTabDown(nil)
        #expect(shape(browser) == expected && browser.tabs[browser.selected].title == title)
        browser.tabs.forEach { $0.unload() }
    }

    @Test(arguments: [
        (["r", "A:f1,f2", "s"], 0, true, false), (["r", "A:f1,f2", "s"], 3, false, false),
        (["r", "A:f1,f2", "s"], 3, true, true), (["A:f1"], 0, true, true), (["A:f1"], 0, false, true),
    ])
    func moveTabItemIsOffWhenNothingMoves(spec: [String], selected: Int, up: Bool, enabled: Bool) {
        let browser = browser(spec)
        browser.select(selected)
        #expect(browser.canMoveSelectedTab(up: up) == enabled)
        browser.tabs.forEach { $0.unload() }
    }

    /// Ruling after P7-FIX-1: ⌃⇥ / ⌃⇧⇥ skip the tabs of a collapsed folder.
    @Test(arguments: [(true, "r2"), (false, "r2")])
    func controlTabSkipsACollapsedFolder(next: Bool, title: String) {
        let browser = browser(["r0", "A*:a1", "r2"])
        browser.select(0)
        next ? browser.selectNextTab(nil) : browser.selectPreviousTab(nil)
        #expect(browser.tabs[browser.selected].title == title)
        browser.tabs.forEach { $0.unload() }
    }
}
