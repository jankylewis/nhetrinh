import Foundation
import NhetrinhCore

/// R36 to R38: the P6 readback (hubs/product/plan/M3_V1_RELEASE.md), the memory guard. Pressure is
/// simulated through the probe's `pressure` request (NHT_READBACK=1 only): real system pressure is
/// never made on the headmate's machine. A warning takes background tabs idle past 1 minute, so
/// R36 and R37 wait that minute: a warning sent at once proves nothing.
enum PressureSteps {
    static let all: [Step] = [
        Step(id: "R36", name: "a memory warning leaves 1 page process; the unloaded tab comes back with its history",
             run: warningLeavesOnePage),
        Step(id: "R37", name: "a playing tab is still loaded after a memory warning", run: playingTabSurvives),
        Step(id: "R38", name: "3 tabs, 2 unloaded, cost the one-tab budget + 15 MB", run: budgetWithTwoUnloaded),
    ]

    /// Past `UnloadPolicy.warningLimit`, with room for the app's clock and the probe's round trips.
    static let pastTheWarningLimit: TimeInterval = UnloadPolicy.warningLimit + 3

    static func warningLeavesOnePage(_ app: AppSession) throws -> String {
        try ToolSteps.fresh(app)
        try LifecycleSteps.open(app, page: 1)
        try LifecycleSteps.open(app, page: 2)
        for page in 3...4 {
            try app.act(.newTab, "File > New Tab")
            try LifecycleSteps.open(app, page: page)
        }
        let before = try pageProcesses(app, until: 3)
        try expect(before == 3, "3 loaded tabs: \(before) page process(es) run, 3 expected")
        try simulate(.warning, on: app)
        Thread.sleep(forTimeInterval: 2)
        let early = try app.state().loaded
        try expect(early == [true, true, true], "a warning with every tab used within 1 min: loaded \(early)")
        Thread.sleep(forTimeInterval: pastTheWarningLimit)
        try simulate(.warning, on: app)
        try expect(waitUntil(10) { (try? app.state().loaded) == [false, false, true] },
                   "a warning past 1 min idle: loaded per row \((try? app.state().loaded) ?? [])")
        let after = try pageProcesses(app, until: 1)
        try expect(after == 1, "after the warning \(after) page process(es) run, 1 expected")
        return "3 loaded tabs, 3 page processes; a warning at once unloaded none; a warning "
            + "\(Int(pastTheWarningLimit)) s later unloaded rows 1 and 2: 1 page process left; " + (try comesBack(app))
    }

    /// Row 1 (test page 1, then 2) clicked: it loads test page 2, and Tabs > Back goes to test page 1.
    private static func comesBack(_ app: AppSession) throws -> String {
        let pages = try LifecycleSteps.pages()
        try app.act(.select(0), "select sidebar row 1")
        var state = try app.state()
        let loaded = waitUntil(15) {
            state = (try? app.state()) ?? state
            return state.loaded.first == true && state.address == pages.url("/page/2")
        }
        try expect(loaded, "clicked the unloaded row 1: loaded \(state.loaded), address \"\(state.address)\"")
        try app.act(.menu(["Tabs", "Back"]), "Tabs > Back")
        let back = waitUntil(15) {
            state = (try? app.state()) ?? state
            return state.address == pages.url("/page/1") && state.title == TestPageContent.title(page: 1)
        }
        try expect(back, "Tabs > Back after the reload: address \"\(state.address)\", title \"\(state.title)\"")
        return "row 1 clicked loaded test page 2, Tabs > Back went to test page 1"
    }

    /// Row 1 plays, row 2 silent, row 3 selected; a minute later a warning, then a critical level.
    static func playingTabSurvives(_ app: AppSession) throws -> String {
        guard ToolSteps.forgetPrefs() else { throw StepError.cannotDrive("the readback profile's prefs stay") }
        try UnloadSteps.startAudio(app, env: [:])
        for page in 1...2 {
            try app.act(.newTab, "File > New Tab")
            try LifecycleSteps.open(app, page: page)
        }
        Thread.sleep(forTimeInterval: pastTheWarningLimit)
        try simulate(.warning, on: app)
        var state = try app.state()
        let silentGone = waitUntil(10) {
            state = (try? app.state()) ?? state
            return state.loaded == [true, false, true]
        }
        try expect(silentGone, "a warning past 1 min idle: loaded per row \(state.loaded), not [true, false, true]")
        try simulate(.critical, on: app)
        Thread.sleep(forTimeInterval: 3)
        state = try app.state()
        try expect(state.loaded.first == true, "after a critical level the playing row 1 is unloaded")
        let row = state.rows.first ?? ""
        try expect(row == TestPageContent.playingTitle, "the playing tab stays loaded but row 1 reads \"\(row)\"")
        return "row 1 playing, row 2 silent, row 3 selected, \(Int(pastTheWarningLimit)) s idle; a warning unloaded "
            + "row 2 only; a critical level after it: row 1 still loaded and playing"
    }

    /// R8's reading on 3 example sites, 2 of them unloaded by a critical level.
    static func budgetWithTwoUnloaded(_ app: AppSession) throws -> String {
        try ToolSteps.fresh(app)
        for (index, site) in ["https://example.com", "https://example.org", "https://example.net"].enumerated() {
            if index > 0 { try app.act(.newTab, "File > New Tab") }
            try app.act(.navigate(site), "address bar: \(site), Return")
            let shown = waitUntil(20) {
                let state = try? app.state()
                return state?.loading == false && state?.title == "Example Domain"
            }
            try expect(shown, "\(site): not loaded after 20 s")
        }
        try simulate(.critical, on: app)
        try expect(waitUntil(10) { (try? app.state().loaded) == [false, false, true] },
                   "a critical level: loaded per row \((try? app.state().loaded) ?? [])")
        let pages = try pageProcesses(app, until: 1)
        try expect(pages == 1, "2 tabs unloaded: \(pages) page process(es) run, 1 expected")
        Thread.sleep(forTimeInterval: 6)
        let (memory, helpers) = SystemSteps.memorySamples(of: app.pid, extra: Budget.pressureExtra)
        if let why = memory.noReading { throw StepError.cannotDrive("3 tabs, 2 unloaded: \(why)") }
        try expect(memory.holds, "3 tabs, 2 unloaded: " + memory.line(helpers: helpers))
        return "3 example sites, 2 unloaded by a critical level, 6 s later: " + memory.line(helpers: helpers)
    }

    private static func simulate(_ level: UnloadPolicy.Pressure, on app: AppSession) throws {
        try app.act(.pressure(level), "simulate memory pressure \(level.rawValue) (probe, NHT_READBACK=1)")
    }

    /// The page processes once there are `count` (15 s at most), as many as there are then.
    private static func pageProcesses(_ app: AppSession, until count: Int) throws -> Int {
        waitUntil(15, every: 0.5) { Footprint.pageProcesses(of: app.pid).count == count }
        return Footprint.pageProcesses(of: app.pid).count
    }
}
