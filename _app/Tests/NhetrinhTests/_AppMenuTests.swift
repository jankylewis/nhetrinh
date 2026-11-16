import AppKit
import Testing
@testable import Nhetrinh

/// The readback launches the app without activating it (D18): there is no key window, so a menu
/// item with no target finds nobody in the responder chain (NT-UIX-001). This test process is not
/// active and has no key window either: the same condition.
@MainActor
struct AppMenuTests {
    static let browserItems: [[String]] = [
        ["File", "New Tab"], ["File", "Close Tab"], ["File", "Open Location"],
        ["View", "Toggle Sidebar"], ["View", "Reload"],
        ["Tabs", "Back"], ["Tabs", "Forward"], ["Tabs", "Tab 1"], ["Tabs", "Tab 9"],
        ["File", "Reopen Closed Tab"], ["View", "Stop"], ["Tabs", "Select Next Tab"], ["Tabs", "Select Previous Tab"],
        ["Tabs", "Move Tab Up"], ["Tabs", "Move Tab Down"], ["File", "Print…"],
    ]

    @Test(arguments: browserItems)
    func browserItemReachesTheBrowserWithNoKeyWindow(path: [String]) throws {
        _ = NSApplication.shared
        #expect(NSApp.keyWindow == nil)
        let browser = BrowserWindowController()
        let menu = AppMenu.build(browser: browser)
        let item = try #require(Self.item(path, in: menu))
        let action = try #require(item.action)
        let target = NSApp.target(forAction: action, to: item.target, from: item) as AnyObject?
        #expect(target === browser, "\(path.joined(separator: " > ")) reaches \(String(describing: target))")
    }

    @Test(arguments: [
        (["File", "New Tab"], "t"), (["File", "Close Tab"], "w"), (["File", "Open Location"], "l"),
        (["View", "Toggle Sidebar"], "s"), (["View", "Reload"], "r"), (["Tabs", "Back"], "["),
        (["Tabs", "Forward"], "]"), (["Tabs", "Tab 1"], "1"), (["Tabs", "Tab 9"], "9"),
        (["File", "Print…"], "p"),
    ])
    func browserItemKeepsItsShortcut(path: [String], key: String) throws {
        let menu = AppMenu.build(browser: BrowserWindowController())
        let item = try #require(Self.item(path, in: menu))
        #expect(item.keyEquivalent == key && item.keyEquivalentModifierMask == .command)
    }

    /// P2 shortcuts, as the menu shows them (the probe's `state.shortcuts`).
    @Test(arguments: [
        ("File > Reopen Closed Tab", "⇧⌘T"), ("View > Stop", "⌘."),
        ("Tabs > Select Next Tab", "⌃⇥"), ("Tabs > Select Previous Tab", "⌃⇧⇥"),
    ])
    func p2ShortcutReadsLikeTheMenu(path: String, shortcut: String) {
        _ = NSApplication.shared
        let browser = BrowserWindowController()
        #expect(browser.probeState(menu: AppMenu.build(browser: browser)).shortcuts[path] == shortcut)
    }

    /// Edit items act on the focused text: they must stay on the responder chain (nil target).
    @Test(arguments: ["Undo", "Redo", "Cut", "Copy", "Paste", "Select All"])
    func editItemHasNoFixedTarget(title: String) throws {
        let menu = AppMenu.build(browser: BrowserWindowController())
        let item = try #require(Self.item(["Edit", title], in: menu))
        #expect(item.target == nil)
    }

    static func item(_ path: [String], in menu: NSMenu) -> NSMenuItem? {
        var current: NSMenu? = menu
        var found: NSMenuItem?
        for title in path {
            found = current?.item(withTitle: title)
            current = found?.submenu
        }
        return found
    }
}
