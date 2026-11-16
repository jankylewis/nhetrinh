import AppKit
import NhetrinhCore
import Testing
import WebKit
@testable import Nhetrinh

/// P6 memory guard (hubs/product/plan/M3_V1_RELEASE.md) through the readback's "simulate pressure"
/// request: the path a macOS memory pressure event takes too. No page is loaded: every tab has a web
/// view with no URL, so nothing goes to the network.
@MainActor
struct MemoryGuardTests {
    /// 3 tabs with a web view each; row 3 selected; row 1 idle `firstIdle` seconds, the others just used.
    private func browser(firstIdle: TimeInterval) -> BrowserWindowController {
        _ = NSApplication.shared
        let browser = BrowserWindowController()
        browser.tabs = (1...3).map { Tab(url: nil, title: "t\($0)") }
        browser.tabs.forEach { browser.load($0) }
        browser.selected = 2
        browser.tabs[0].lastActive = Date() - firstIdle
        browser.refreshChrome()
        return browser
    }

    /// Wait (60 s at most) until `done` holds; the main queue runs meanwhile, WebKit answers on it.
    private func eventually(_ done: () -> Bool) async -> Bool {
        for _ in 0..<600 where !done() { try? await Task.sleep(nanoseconds: 100_000_000) }
        return done()
    }

    /// Warning: background tabs idle past 1 minute. Critical: every background tab. Never the selected one.
    @Test(arguments: [
        (UnloadPolicy.Pressure.warning, 120.0, [false, true, true]),
        (.critical, 0.0, [false, false, true]),
        (.critical, 120.0, [false, false, true]),
    ])
    func pressureUnloadsBackgroundTabs(level: UnloadPolicy.Pressure, firstIdle: TimeInterval,
                                       loaded: [Bool]) async {
        let browser = browser(firstIdle: firstIdle)
        #expect(browser.probeAnswer(.pressure(level), menu: nil) == .done)
        let unloaded = await eventually { browser.tabs.map(\.isLoaded) == loaded }
        #expect(unloaded, "loaded per tab: \(browser.tabs.map(\.isLoaded)), expected \(loaded)")
    }

    /// A warning unloads no tab used within the last minute: the normal limit (10 min) and 1 min both wait.
    @Test(arguments: [UnloadPolicy.Pressure.normal, .warning])
    func pressureKeepsTabsUsedJustNow(level: UnloadPolicy.Pressure) async {
        let browser = browser(firstIdle: 30)
        #expect(browser.probeAnswer(.pressure(level), menu: nil) == .done)
        try? await Task.sleep(nanoseconds: 500_000_000)
        #expect(browser.tabs.map(\.isLoaded) == [true, true, true])
    }

    /// The favicon cache is emptied at critical only; the rows keep the icons they show.
    @Test(arguments: [(UnloadPolicy.Pressure.normal, 1), (.warning, 1), (.critical, 0)])
    func criticalEmptiesTheFaviconCache(level: UnloadPolicy.Pressure, kept: Int) throws {
        let browser = browser(firstIdle: 0)
        let url = try #require(URL(string: "https://example.com/favicon.ico"))
        browser.favicons.cache[url] = NSImage(size: NSSize(width: 16, height: 16))
        _ = browser.probeAnswer(.pressure(level), menu: nil)
        #expect(browser.favicons.count == kept)
    }

    /// An unloaded tab holds no web view, and nothing else keeps it: it is gone once the main queue
    /// turns (P6-BUILD-1 saw it released after a turn, not at once; what holds it until then: not proven).
    @Test(arguments: [0, 1])
    func anUnloadedTabHoldsNoWebView(row: Int) async {
        let browser = browser(firstIdle: 0)
        weak var dropped: WKWebView?
        autoreleasepool {
            dropped = browser.tabs[row].webView
            browser.tabs[row].unload()
        }
        let gone = await eventually { dropped == nil }
        #expect(gone && browser.tabs[row].webView == nil && !browser.tabs[row].isLoaded)
    }

    /// macOS's event, as the guard reads it (by raw value: the event type is not `Sendable`).
    @Test(arguments: [
        (DispatchSource.MemoryPressureEvent.normal.rawValue, UnloadPolicy.Pressure.normal),
        (DispatchSource.MemoryPressureEvent.warning.rawValue, .warning),
        (DispatchSource.MemoryPressureEvent.critical.rawValue, .critical),
        (DispatchSource.MemoryPressureEvent([.warning, .critical]).rawValue, .critical),
    ])
    func theGuardReadsTheMostSevereLevel(event: UInt, level: UnloadPolicy.Pressure) {
        #expect(MemoryGuard.level(DispatchSource.MemoryPressureEvent(rawValue: event)) == level)
    }
}
