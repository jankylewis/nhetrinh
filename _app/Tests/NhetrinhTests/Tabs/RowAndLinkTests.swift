import AppKit
import Testing
import WebKit
@testable import Nhetrinh

/// P2 paths no readback step reaches (P2-FIX-1): ⌘-click (`decidePolicyFor`), a middle button event,
/// the row's close button (hover stays the user's way), the progress line. No page loads.
@MainActor
struct RowAndLinkTests {
    /// WebKit gives the delegate its own action; a test gives one with the fields the policy reads.
    private final class Action: WKNavigationAction {
        let url: URL?, flags: NSEvent.ModifierFlags, type: WKNavigationType
        init(_ url: URL?, _ flags: NSEvent.ModifierFlags, _ type: WKNavigationType = .linkActivated) {
            (self.url, self.flags, self.type) = (url, flags, type)
            super.init()
        }
        override var request: URLRequest { URLRequest(url: url ?? URL(fileURLWithPath: "/")) }
        override var modifierFlags: NSEvent.ModifierFlags { flags }
        override var navigationType: WKNavigationType { type }
    }

    private func browser(_ count: Int, selected: Int) -> BrowserWindowController {
        _ = NSApplication.shared
        let browser = BrowserWindowController()
        browser.tabs = (1...count).map { Tab(url: URL(string: "about:blank?\($0)"), title: "t\($0)") }
        browser.selected = selected
        browser.refreshChrome()
        browser.window?.layoutIfNeeded()
        return browser
    }

    @Test(arguments: [
        ("https://example.com/a", .command, .linkActivated, false, 3),
        ("https://example.com/a", [], .linkActivated, true, 2),
        ("https://example.com/a", .command, .formSubmitted, true, 2),
        ("javascript:void(0)", .command, .linkActivated, true, 2),
    ] as [(String, NSEvent.ModifierFlags, WKNavigationType, Bool, Int)])
    func commandClickOpensABackgroundTab(link: String, flags: NSEvent.ModifierFlags, type: WKNavigationType,
                                         allowed: Bool, rows: Int) {
        let browser = browser(2, selected: 0)
        var policy: WKNavigationActionPolicy?
        let view = BrowserWebView(frame: .zero, configuration: WKWebViewConfiguration())
        browser.webView(view, decidePolicyFor: Action(URL(string: link), flags, type)) { policy = $0 }
        #expect(policy == (allowed ? .allow : .cancel))
        #expect(browser.tabs.count == rows && browser.selected == 0)
        #expect(allowed || browser.tabs[1].url == URL(string: link))
    }

    /// The real event of the middle button (button 2), with the window at the screen's origin so the
    /// event's screen point is its window point. Any other button closes nothing.
    @Test(arguments: [(CGMouseButton.center, 2), (.right, 3)])
    func middleButtonClosesTheRowUnderIt(button: CGMouseButton, rows: Int) throws {
        let browser = browser(3, selected: 2)
        let window = try #require(browser.window)
        window.setFrameOrigin(.zero)
        let table = browser.sidebar.table
        let point = try #require(table.center(ofRow: 0))
        let height = NSScreen.screens.first?.frame.height ?? 0
        let screen = CGPoint(x: point.x, y: height - point.y)
        let cgEvent = try #require(CGEvent(mouseEventSource: nil, mouseType: .otherMouseUp,
                                           mouseCursorPosition: screen, mouseButton: button))
        let event = try #require(NSEvent(cgEvent: cgEvent))
        table.otherMouseUp(with: event)
        #expect(browser.tabs.map(\.title) == (rows == 2 ? ["t2", "t3"] : ["t1", "t2", "t3"]))
    }

    @Test func rowCloseButtonClosesItsRow() throws {
        let browser = browser(3, selected: 0)
        let row = try #require(browser.sidebar.table.view(atColumn: 0, row: 1, makeIfNecessary: true) as? TabRowView)
        let buttons = row.subviews.compactMap { $0 as? NSButton }
        let close = try #require(buttons.first { $0.accessibilityLabel() == "Close Tab" })
        close.performClick(nil)
        #expect(browser.tabs.map(\.title) == ["t1", "t3"] && browser.selected == 0)
    }

    /// P2: no row's menu below the rows; P8-GROUPS-1: the sidebar's own, New Group… only.
    @Test func aRightClickBelowTheRowsGivesTheSidebarsMenu() throws {
        let browser = browser(2, selected: 0)
        let table = browser.sidebar.table
        let last = try #require(table.center(ofRow: 1))
        let below = NSPoint(x: last.x, y: last.y - 10 * table.rowHeight)
        let click = try #require(NSEvent.mouseEvent(with: .rightMouseDown, location: below, modifierFlags: [],
                                                    timestamp: 0, windowNumber: browser.window?.windowNumber ?? 0,
                                                    context: nil, eventNumber: 0, clickCount: 1, pressure: 1))
        let menu = table.menu(for: click)
        #expect(menu?.items.map(\.title) == [SidebarView.newGroup] && table.menuRow == -1)
    }

    @Test func theRowShowsTheTabsIcon() {
        let browser = browser(2, selected: 0)
        browser.tabs[1].icon = NSImage(size: NSSize(width: 16, height: 16))
        browser.refreshChrome()
        browser.window?.layoutIfNeeded()
        #expect(browser.sidebar.shownIcons == [false, true])
    }

    @Test func progressLineFollowsTheLoading() {
        let toolbar = ToolbarView(frame: NSRect(x: 0, y: 0, width: 400, height: 36))
        toolbar.showLoading(true, progress: 0.5)
        toolbar.layoutSubtreeIfNeeded()
        #expect(toolbar.progressShown && toolbar.progressWidth == 200)
        toolbar.showLoading(false, progress: 1)
        #expect(!toolbar.progressShown)
    }
}
