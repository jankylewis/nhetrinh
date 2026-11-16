import AppKit
import Testing
import WebKit
@testable import Nhetrinh

/// P2 page chrome: the link menu's Open Link in New Tab, reload that becomes stop. No page loads.
@MainActor
struct PageChromeTests {
    private final class Sink: NSObject {
        var hits = 0
        @objc func hit(_ sender: Any?) { hits += 1 }
    }

    private func linkMenu(_ sink: Sink) -> (NSMenu, NSMenuItem) {
        let menu = NSMenu()
        let original = NSMenuItem(title: "Open Link in New Window", action: #selector(Sink.hit(_:)), keyEquivalent: "")
        original.identifier = NSUserInterfaceItemIdentifier(BrowserWebView.newWindowIdentifier)
        original.target = sink
        menu.addItem(NSMenuItem(title: "Open Link", action: nil, keyEquivalent: ""))
        menu.addItem(original)
        menu.addItem(NSMenuItem(title: "Copy Link", action: nil, keyEquivalent: ""))
        return (menu, original)
    }

    @Test func linkMenuSaysNewTabWhereWebKitSaysNewWindow() {
        let view = BrowserWebView(frame: .zero, configuration: WKWebViewConfiguration())
        let (menu, original) = linkMenu(Sink())
        view.rewrite(menu)
        #expect(menu.items.map(\.title) == ["Open Link", "Open Link in New Tab", "Copy Link"])
        #expect(menu.items[1].representedObject as? NSMenuItem === original)
    }

    @Test func aMenuWithoutTheLinkItemStaysAsItIs() {
        let view = BrowserWebView(frame: .zero, configuration: WKWebViewConfiguration())
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Reload", action: nil, keyEquivalent: ""))
        view.rewrite(menu)
        #expect(menu.items.map(\.title) == ["Reload"])
    }

    /// Our item runs WebKit's own, and the web view WebKit then asks for is a background tab, once.
    @Test(arguments: [(0.0, true), (2.0, true), (10.0, false)])
    func newTabItemRunsWebKitsItemAndAsksForABackgroundTab(after: Double, background: Bool) {
        _ = NSApplication.shared
        let view = BrowserWebView(frame: .zero, configuration: WKWebViewConfiguration())
        let sink = Sink()
        let (menu, _) = linkMenu(sink)
        view.rewrite(menu)
        menu.performActionForItem(at: 1)
        #expect(sink.hits == 1)
        #expect(view.takesBackgroundOpen(now: Date().addingTimeInterval(after)) == background)
        #expect(view.takesBackgroundOpen() == false)
    }

    @Test func reloadIsStopWhileThePageLoads() {
        let toolbar = ToolbarView()
        var stops = 0, reloads = 0
        toolbar.onStop = { stops += 1 }
        toolbar.onReload = { reloads += 1 }
        #expect(toolbar.reloadLabel == "Reload")
        toolbar.showLoading(true, progress: 0.3)
        #expect(toolbar.reloadLabel == "Stop" && toolbar.press("Stop") && !toolbar.press("Reload"))
        toolbar.showLoading(false, progress: 1)
        #expect(toolbar.reloadLabel == "Reload" && toolbar.press("Reload"))
        #expect(stops == 1 && reloads == 1)
    }
}
