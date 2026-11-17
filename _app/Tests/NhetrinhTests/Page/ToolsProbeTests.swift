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
        browser.closeAfterTest()
    }

    /// A value the hub does not offer is refused; bad minutes keep the old value.
    @Test(arguments: [("Search engine", "AltaVista"), ("Appearance", "Sepia"), ("Font", "Large")])
    func unknownSettingFails(name: String, value: String) {
        let (browser, menu) = browser()
        browser.showSettingsHub(nil)
        #expect(browser.probeAnswer(.setting(name: name, value: value), menu: menu)
                == .failed("the Settings Hub has no \(name) \(value)"))
        browser.hub?.close()
        browser.closeAfterTest()
    }

    @Test(arguments: ["0", "-3", "ten", ""])
    func badMinutesKeepTheOldValue(text: String) {
        let (browser, menu) = browser()
        browser.showSettingsHub(nil)
        _ = browser.probeAnswer(.setting(name: "Unload idle tabs after", value: text), menu: menu)
        #expect(browser.prefs.idleUnloadMinutes == Prefs.defaultIdleMinutes)
        #expect(browser.hub?.minutes.stringValue == "\(Prefs.defaultIdleMinutes)")
        browser.hub?.close()
        browser.closeAfterTest()
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

/// P5: WebKit and AppKit find the download and link handlers by their Objective-C selectors; a method
/// whose Swift name misses the selector is never called, and nothing else would tell. The probe's
/// `download` refuses a row the footer does not show; a link from another app opens only for the web.
@MainActor
struct OutsideProbeTests {
    @Test(arguments: ["webView:decidePolicyForNavigationResponse:decisionHandler:",
                      "webView:navigationAction:didBecomeDownload:", "webView:navigationResponse:didBecomeDownload:",
                      "webView:decidePolicyForNavigationAction:decisionHandler:"])
    func webKitFindsTheDownloadHandlers(selector: String) {
        _ = NSApplication.shared
        #expect(BrowserWindowController().responds(to: NSSelectorFromString(selector)))
    }

    @Test(arguments: ["download:decideDestinationUsingResponse:suggestedFilename:completionHandler:",
                      "downloadDidFinish:", "download:didFailWithError:resumeData:"])
    func webKitFindsTheDownloadDelegate(selector: String) {
        #expect(Downloads(folder: nil).responds(to: NSSelectorFromString(selector)))
    }

    @Test func appKitFindsTheLinkHandler() {
        #expect(AppDelegate().responds(to: NSSelectorFromString("application:openURLs:")))
    }

    @Test(arguments: [("Cancel", 0), ("Show in Finder", 2)])
    func downloadRowNotShownFails(item: String, row: Int) {
        _ = NSApplication.shared
        let browser = BrowserWindowController()
        #expect(browser.probeAnswer(.download(row: row, item: item), menu: nil)
                == .failed("the footer has no download row \(row)"))
        #expect(browser.probeState(menu: nil).downloads == [])
        #expect(browser.sidebar.downloads.isHidden)
    }

    @Test(arguments: [("mailto:a@example.com", 0), ("file:///tmp/a.html", 0), ("HTTP://127.0.0.1:9/a", 1)])
    func linkFromAnotherAppOpensOnlyForTheWeb(link: String, added: Int) throws {
        _ = NSApplication.shared
        let browser = BrowserWindowController()
        browser.openIncoming([try #require(URL(string: link))])
        #expect(browser.tabs.count == added)
        #expect(browser.selected == added - 1)
        browser.tabs.first?.unload()
    }
}
