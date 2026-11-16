import Foundation
import NhetrinhCore

/// R11 and R12: idle unload with the limit set to 5 s for the run (NHT_UNLOAD_AFTER_S).
enum UnloadSteps {
    static let shortLimit = ["NHT_UNLOAD_AFTER_S": "5"]

    /// NT-TAB-001: a background tab that plays stays loaded past the limit; a silent one is unloaded.
    static func playingTabStaysLoaded(_ app: AppSession) throws -> String {
        try startAudio(app)
        try app.act(.newTab, "File > New Tab")
        try LifecycleSteps.open(app, page: 1)
        try app.act(.newTab, "File > New Tab")
        var state = try app.state()
        var playingUnloaded = false
        let watch = {
            state = (try? app.state()) ?? state
            if state.loaded.first == false { playingUnloaded = true }
        }
        let silentUnloaded = waitUntil(30, every: 0.5) {
            watch()
            return state.loaded.count == 3 && !state.loaded[1]
        }
        try expect(silentUnloaded, "idle limit 5 s: after 30 s the silent tab (row 2) is still loaded")
        waitUntil(10, every: 0.5) {
            watch()
            return playingUnloaded
        }
        try expect(!playingUnloaded, "idle limit 5 s: the playing tab (row 1) was unloaded")
        let row = state.rows.first ?? ""
        try expect(row == TestPageContent.playingTitle, "the playing tab stays loaded but row 1 reads \"\(row)\"")
        return "idle limit 5 s: the silent background tab was unloaded; the playing one stayed loaded "
            + "and playing 10 s past that"
    }

    /// A fresh start with the short limit; row 1 plays the test audio (its title says so).
    private static func startAudio(_ app: AppSession) throws {
        let audio = try LifecycleSteps.pages().url("/play")
        try LifecycleSteps.freshStart(app, env: shortLimit)
        try app.act(.navigate(audio), "address bar: the test audio page, Return")
        let started = waitUntil(15) { (try? app.state().rows.first) == TestPageContent.playingTitle }
        guard started else {
            let row = (try? app.state().rows.first) ?? ""
            throw StepError.cannotDrive("the test audio did not start in 15 s; row 1 reads \"\(row)\"")
        }
    }

    /// An unloaded tab gets its `interactionState` back: the same address, and Tabs > Back works.
    static func unloadedTabKeepsHistory(_ app: AppSession) throws -> String {
        let pages = try LifecycleSteps.pages()
        try LifecycleSteps.freshStart(app, env: shortLimit)
        try LifecycleSteps.open(app, page: 1)
        try LifecycleSteps.open(app, page: 2)
        try app.act(.newTab, "File > New Tab")
        let unloaded = waitUntil(30, every: 0.5) { (try? app.state().loaded.first) == false }
        try expect(unloaded, "idle limit 5 s: after 30 s row 1 is still loaded")
        try app.act(.select(0), "select sidebar row 1")
        let second = pages.url("/page/2")
        var state = try app.state()
        let reloaded = waitUntil(15) {
            state = (try? app.state()) ?? state
            return state.loaded.first == true && state.address == second
        }
        try expect(reloaded, "selected the unloaded row 1; loaded \(state.loaded), address \"\(state.address)\"")
        try app.act(.menu(["Tabs", "Back"]), "Tabs > Back")
        let first = pages.url("/page/1")
        let back = waitUntil(15) {
            state = (try? app.state()) ?? state
            return state.address == first && state.title == TestPageContent.title(page: 1)
        }
        try expect(back, "Tabs > Back after the reload: address \"\(state.address)\", title \"\(state.title)\"")
        return "row 1 (test page 1, then 2) was unloaded after 5 s idle; selecting it loaded test page 2; "
            + "Tabs > Back went to test page 1"
    }
}
