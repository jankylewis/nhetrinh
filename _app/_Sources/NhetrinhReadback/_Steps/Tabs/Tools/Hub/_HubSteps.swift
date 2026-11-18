import Foundation
import NhetrinhCore

/// R29 to R30a: the Settings Hub (D19), opened from nhetrinh > Settings Hub…, its controls set as a user picks them.
enum HubSteps {
    static func openHub(_ app: AppSession) throws {
        try app.act(.menu(["nhetrinh", "Settings Hub…"]), "nhetrinh > Settings Hub…")
        _ = try ToolSteps.until(app, { $0.hubShown }, else: { _ in "nhetrinh > Settings Hub…: no window after 10 s" })
    }

    static func engine(_ app: AppSession) throws -> String {
        try ToolSteps.fresh(app)
        try openHub(app)
        try app.act(.setting(name: "Search engine", value: "DuckDuckGo"), "Settings Hub: Search engine DuckDuckGo")
        try app.act(.navigate("nhetrinh readback words"), "address bar: nhetrinh readback words, Return")
        let wanted = SearchEngine.duckDuckGo.template + "nhetrinh%20readback%20words"
        var seen = ""
        let found = waitUntil(10, every: 0.05) {
            seen = (try? app.addressText()) ?? seen
            return seen.hasPrefix(wanted)
        }
        try expect(found, "after DuckDuckGo the address bar never held \(wanted); last \"\(seen)\"")
        try keptAfterRelaunch(app, wanted: wanted)
        return "Settings Hub: Search engine DuckDuckGo; typed words: the address bar held \(wanted); "
            + "after Quit and a launch the next search goes there too"
    }

    /// F12 (P4P6-FIX-1): the engine is kept: after Quit and a launch, words go to DuckDuckGo again.
    private static func keptAfterRelaunch(_ app: AppSession, wanted: String) throws {
        try app.act(.menu(["nhetrinh", "Quit nhetrinh"]), "nhetrinh > Quit nhetrinh")
        try expect(app.waitForEnd(10), "nhetrinh > Quit nhetrinh: the app still runs after 10 s")
        try app.launch(probe: true)
        try app.act(.navigate("nhetrinh readback words"), "after the launch: the same words, Return")
        var seen = ""
        let kept = waitUntil(10, every: 0.05) {
            seen = (try? app.addressText()) ?? seen
            return seen.hasPrefix(wanted)
        }
        try expect(kept, "after Quit and a launch the search went to \"\(seen)\", not DuckDuckGo")
    }

    static func clearData(_ app: AppSession) throws -> String {
        try ToolSteps.fresh(app)
        try ToolSteps.open(app, "/cookie/set", title: ToolPages.cookieSetTitle)
        try ToolSteps.open(app, "/cookie/read", title: ToolPages.cookieTitle)
        try openHub(app)
        try app.act(.button(SettingsTitles.clear), "Settings Hub: \(SettingsTitles.clear)")
        let sheet = try SheetDriving.sheet(app, text: "Clear website data?")
        try expect(Set(sheet.sheetButtons) == ["Cancel", "Clear Last Hour", "Clear All"],
                   "the clear sheet's buttons: \(sheet.sheetButtons)")
        try SheetDriving.press(app, "Clear All")
        _ = try SheetDriving.gone(app, after: "Clear All")
        Thread.sleep(forTimeInterval: 2)  // WebKit removes the data in the background
        try ToolSteps.open(app, "/cookie/read", title: ToolPages.noCookieTitle)
        return "a page set a cookie (read back: nhetrinh=readback); Settings Hub > \(SettingsTitles.clear) "
            + "\(sheet.sheetButtons) > Clear All: the page reads no cookie"
    }

    static func appearance(_ app: AppSession) throws -> String {
        try ToolSteps.fresh(app)
        try openHub(app)
        try app.act(.setting(name: "Appearance", value: "Dark"), "Settings Hub: Appearance Dark")
        _ = try ToolSteps.until(app, { $0.appearance == "dark" }, else: { "Dark: the window is \($0.appearance)" })
        try ToolSteps.open(app, "/scheme", title: ToolPages.schemeTitle(dark: true))
        try app.act(.menu(["nhetrinh", "Quit nhetrinh"]), "nhetrinh > Quit nhetrinh")
        try expect(app.waitForEnd(10), "nhetrinh > Quit nhetrinh: the app still runs after 10 s")
        try app.launch(probe: true)
        let dark = ToolPages.schemeTitle(dark: true)
        _ = try ToolSteps.until(app, within: 15, { $0.appearance == "dark" && $0.title == dark }, else: {
            "after the relaunch the window is \($0.appearance), the page \"\($0.title)\""
        })
        try openHub(app)
        let light = try choose(app, "Light", page: ToolPages.schemeTitle(dark: false))
        let macOS = systemIsDark() ? "dark" : "light"
        let system = try choose(app, "System", page: ToolPages.schemeTitle(dark: macOS == "dark"))
        if let failure = appearanceFailure(light: light.appearance, system: system.appearance, macOS: macOS) {
            throw StepError.fail(failure)
        }
        return "Appearance Dark: window dark, the page read dark; after Quit and a launch: still dark; "
            + "Light: the window and the page light; System: both follow macOS (\(macOS))"
    }

    /// Choose `value` in the hub; the state once the page reads `page` (or 10 s, then the last state).
    private static func choose(_ app: AppSession, _ value: String, page: String) throws -> ProbeState {
        try app.act(.setting(name: "Appearance", value: value), "Settings Hub: Appearance \(value)")
        var state = try app.state()
        waitUntil(10) {
            state = (try? app.state()) ?? state
            return state.title == page
        }
        try expect(state.title == page, "Appearance \(value): the page reads \"\(state.title)\", not \"\(page)\"")
        return state
    }

    /// Why R30a fails, or nil: Light reads light; System equals macOS's look (so differs from Light when
    /// macOS is dark).
    static func appearanceFailure(light: String, system: String, macOS: String) -> String? {
        if light != "light" { return "Light: the window is \(light)" }
        if system != macOS { return "System: the window is \(system), macOS is \(macOS)" }
        return nil
    }

    /// macOS's own look, as the readback's process reads it.
    private static func systemIsDark() -> Bool {
        UserDefaults.standard.string(forKey: "AppleInterfaceStyle") == "Dark"
    }
}

/// The Settings Hub's words the readback presses (the app's `SettingsHub.clearTitle`).
enum SettingsTitles {
    static let clear = "Clear Website Data…"
}
