import AppKit
import NhetrinhCore
import Testing
@testable import Nhetrinh

/// P4: the probe reaches the Settings Hub and the find bar as a user does (D18, D23), with no app
/// launched. No prefs folder: nothing is saved. Appearance is not set here: it would change this process.
@MainActor
struct ToolsProbeTests {
    private func browser() -> (BrowserWindowController, NSMenu) {
        _ = NSApplication.shared
        let browser = BrowserWindowController()
        return (browser, AppMenu.build(browser: browser))
    }

    @Test(arguments: [("Search engine", "Bing"), ("Search engine", "DuckDuckGo"),
                      ("Unload idle tabs after", "30")])
    func settingIsAppliedThroughTheHub(name: String, value: String) {
        let (browser, menu) = browser()
        #expect(browser.probeAnswer(.setting(name: name, value: value), menu: menu)
                == .failed("the Settings Hub is not shown"))
        browser.showSettingsHub(nil)
        #expect(browser.probeAnswer(.setting(name: name, value: value), menu: menu) == .done)
        #expect(browser.probeState(menu: menu).hubShown)
        let engine = browser.prefs.searchEngine.title
        #expect(name == "Search engine" ? engine == value : browser.prefs.idleUnloadMinutes == 30)
        browser.hub?.close()
    }

    /// A value the hub does not offer is refused; bad minutes keep the old value.
    @Test(arguments: [("Search engine", "AltaVista"), ("Appearance", "Sepia"), ("Font", "Large")])
    func unknownSettingFails(name: String, value: String) {
        let (browser, menu) = browser()
        browser.showSettingsHub(nil)
        #expect(browser.probeAnswer(.setting(name: name, value: value), menu: menu)
                == .failed("the Settings Hub has no \(name) \(value)"))
        browser.hub?.close()
    }

    @Test(arguments: ["0", "-3", "ten", ""])
    func badMinutesKeepTheOldValue(text: String) {
        let (browser, menu) = browser()
        browser.showSettingsHub(nil)
        _ = browser.probeAnswer(.setting(name: "Unload idle tabs after", value: text), menu: menu)
        #expect(browser.prefs.idleUnloadMinutes == Prefs.defaultIdleMinutes)
        #expect(browser.hub?.minutes.stringValue == "\(Prefs.defaultIdleMinutes)")
        browser.hub?.close()
    }

    /// The find bar: typed into only once shown (Edit > Find > Find…); Close hides it.
    @Test func findBarOpensFromTheMenuAndCloses() {
        let (browser, menu) = browser()
        #expect(browser.probeAnswer(.find("Example"), menu: menu) == .failed("the find bar is not shown"))
        browser.showFind(nil)  // what Edit > Find > Find… sends (no run loop in a main-actor test: NT-GAT-009)
        #expect(browser.probeState(menu: menu).findShown)
        #expect(browser.probeAnswer(.find("Example"), menu: menu) == .done)
        #expect(browser.probeAnswer(.button("Close"), menu: menu) == .done)
        #expect(!browser.probeState(menu: menu).findShown)
    }
}
