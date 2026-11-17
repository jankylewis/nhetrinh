import AppKit
import NhetrinhCore
import Testing
@testable import Nhetrinh

/// P8-SIDE-1 (headmate request): the sidebar on the left or the right, set through the Settings Hub's own control
/// as a user picks it. The hub and the browser window are never shown; no prefs folder: nothing is saved.
@MainActor
struct SidebarSideTests {
    private func browser() -> (BrowserWindowController, SettingsHub) {
        _ = NSApplication.shared
        let browser = BrowserWindowController()
        let hub = SettingsHub(store: WebConfig.shared.websiteDataStore)
        browser.hub = hub
        hub.onChange = { [weak browser] change in browser?.updatePrefs(change) }
        hub.show(browser.prefs)
        return (browser, hub)
    }

    private func state(_ browser: BrowserWindowController, shown: Bool) -> ProbeState {
        NSAnimationContext.runAnimationGroup { $0.duration = 0; browser.sideItem?.isCollapsed = !shown }
        browser.window?.contentView?.layoutSubtreeIfNeeded()
        return browser.probeState(menu: nil)
    }

    /// Right, then Left, the sidebar shown and hidden: on its side, never over the web view; the toolbar's
    /// toggle starts right of the traffic lights unless the sidebar is under them (left, shown).
    @Test(arguments: [true, false])
    func theSidebarSitsOnTheChosenSide(shown: Bool) throws {
        let (browser, hub) = browser()
        for side in [SidebarSide.right, .left] {
            #expect(hub.set(SettingsHub.positionTitle, to: side.title))
            #expect(browser.prefs.sidebarSide == side && hub.position.titleOfSelectedItem == side.title)
            let state = state(browser, shown: shown)
            #expect(state.sidebarSide == side.rawValue && state.toggleSymbol == side.symbol)
            #expect(browser.split.splitViewItems.firstIndex { $0 === browser.sideItem } == (side == .left ? 0 : 1))
            let web = state.webFrame
            if shown {
                let sidebar = state.sidebarFrame
                try #require(sidebar.count == 4 && web.count == 4, "\(side): sidebar \(sidebar), web \(web)")
                #expect(!SidebarLayout.overlap(sidebar, web), "\(side): sidebar \(sidebar), web \(web)")
                #expect(side == .left ? sidebar[0] < web[0] : sidebar[0] > web[0], "\(side): \(sidebar) \(web)")
            } else {
                #expect(state.sidebarFrame.isEmpty && web.first == 0, "\(side) hidden: web \(web)")
            }
            let toggle = try #require(state.toolbarFrames["Toggle Sidebar"])
            let lights = try #require(state.zoomMaxX)
            #expect(toggle[0] >= lights + ToolbarLayout.gap, "\(side), shown \(shown): \(toggle), lights \(lights)")
        }
    }

    /// The width a user dragged is kept when the sidebar moves to the other side and back.
    @Test(arguments: [200.0, 300.0])
    func theWidthIsKeptOnBothSides(width: Double) throws {
        let (browser, hub) = browser()
        browser.keepSidebarWidth(width)
        for side in [SidebarSide.right, .left] {
            #expect(hub.set(SettingsHub.positionTitle, to: side.title))
            let sidebar = state(browser, shown: true).sidebarFrame
            try #require(sidebar.count == 4, "\(side): the sidebar's frame was not read")
            #expect(abs(sidebar[2] - width) <= 1, "\(side): \(sidebar), not \(width) wide")
        }
    }

    /// The toolbar's toggle (as ⌘S does) hides and shows the sidebar on the right too.
    @Test func theToggleWorksOnTheRight() throws {
        let (browser, hub) = browser()
        #expect(hub.set(SettingsHub.positionTitle, to: "Right"))
        for collapsed in [true, false] {
            NSAnimationContext.runAnimationGroup { $0.duration = 0; #expect(browser.toolbar.press("Toggle Sidebar")) }
            #expect(browser.sideItem?.isCollapsed == collapsed)
        }
        #expect(browser.split.splitViewItems.last === browser.sideItem)
    }

    /// A saved Right is placed at launch, and the session's sidebar width is kept on that side.
    @Test func aSavedRightIsPlacedAtLaunch() throws {
        _ = NSApplication.shared
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("nhetrinh-side-\(UUID())")
        defer { try? FileManager.default.removeItem(at: folder) }
        var saved = Prefs()
        saved.sidebarSide = .right
        try PrefsStore.save(saved, in: folder)
        let browser = BrowserWindowController()
        browser.loadPrefs(from: folder)
        let session = Session(tabs: [], selectedIndex: 0, sidebarWidth: 260, collapsed: false)
        browser.restore(TreeSession(migrating: session))
        let state = state(browser, shown: true)
        #expect(state.sidebarSide == "right" && state.toggleSymbol == "sidebar.right")
        let sidebar = state.sidebarFrame
        try #require(sidebar.count == 4 && state.webFrame.count == 4, "\(sidebar) \(state.webFrame)")
        #expect(abs(sidebar[2] - 260) <= 1 && sidebar[0] > state.webFrame[0], "\(sidebar) \(state.webFrame)")
    }
}
