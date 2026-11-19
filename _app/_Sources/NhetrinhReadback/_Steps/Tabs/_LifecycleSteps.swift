import Foundation
import NhetrinhCore

/// R9 to R12: the P1 readback (hubs/product/plan/M1_DAILY_DRIVER.md), tabs across a quit, a kill
/// and an idle unload. Every page is the readback's own (`TestPages`, 127.0.0.1). The app runs in
/// the profile "readback", so only that profile's session is ever reset, never the user's.
enum LifecycleSteps {
    static let all: [Step] = [
        Step(id: "R9", name: "Quit and launch give back the same tabs", run: quitKeepsTabs),
        Step(id: "R10", name: "a kill gives back the last save", run: killKeepsLastSave),
        Step(id: "R11", name: "a playing background tab is never unloaded", run: UnloadSteps.playingTabStaysLoaded),
        Step(id: "R12", name: "an unloaded tab comes back with its history", run: UnloadSteps.unloadedTabKeepsHistory),
    ]

    static func quitKeepsTabs(_ app: AppSession) throws -> String {
        try freshStart(app)
        try openThree(app)
        try app.act(.select(1), "select sidebar row 2")
        let before = try app.state()
        try expect(before.selected == 1, "selected row 2; the sidebar selects row \((before.selected ?? -1) + 1)")
        try app.act(.menu(["nhetrinh", "Quit nhetrinh"]), "nhetrinh > Quit nhetrinh")
        try expect(app.waitForEnd(10), "nhetrinh > Quit nhetrinh: the app still runs after 10 s")
        try app.launch(probe: true)
        let after = try restored(app, rows: before.rows.count)
        try expect(after.rows == before.rows, "after the launch the rows are \(after.rows), not \(before.rows)")
        try expect(after.selected == 1, "after the launch row \((after.selected ?? -1) + 1) is selected, not row 2")
        try expect(after.loaded == [false, true, false], "loaded per row after the launch: \(after.loaded)")
        waitUntil(15) { !Footprint.pageProcesses(of: app.pid).isEmpty }
        Thread.sleep(forTimeInterval: 4)
        let pages = Footprint.pageProcesses(of: app.pid).count
        try expect(pages == 1, "3 tabs restored, 1 selected: \(pages) page process(es) run, 1 is expected")
        return "3 tabs, row 2 selected, nhetrinh > Quit nhetrinh, launch: the same 3 rows, row 2 selected, "
            + "only it loaded, 1 page process"
    }

    static func killKeepsLastSave(_ app: AppSession) throws -> String {
        try freshStart(app)
        try openThree(app)
        try app.act(.newTab, "File > New Tab")
        try open(app, page: 4)
        try app.act(.select(0), "select sidebar row 1")
        Thread.sleep(forTimeInterval: 4)  // the app saves 2 s after a tab change
        let before = try app.state()
        app.killNow()
        try expect(app.waitForEnd(5), "signal 9 sent; the app still runs after 5 s")
        try app.launch(probe: true)
        let after = try restored(app, rows: before.rows.count)
        try expect(after.rows == before.rows, "after the kill and a launch: rows \(after.rows), not \(before.rows)")
        try expect(after.selected == before.selected, "after the kill row \((after.selected ?? -1) + 1) is selected")
        return "4 tabs, row 1 selected, 4 s later signal 9, launch: the same \(after.rows.count) rows, row 1 selected"
    }

    /// The probe's state once the launched app shows `rows` rows (10 s at most).
    static func restored(_ app: AppSession, rows: Int) throws -> ProbeState {
        var state = try app.state()
        waitUntil(10) {
            state = (try? app.state()) ?? state
            return state.rows.count == rows
        }
        return state
    }

    /// The readback profile's own saved session, removed so a step starts from one home tab.
    @discardableResult
    static func forgetSession() -> Bool {
        let folders = AppSession.folders()  // its own and P9's old one (P10-PROFILE)
        for folder in folders {
            for name in [SessionStore.fileName, SessionStore.badFileName, TreeSessionStore.backupFileName] {
                try? FileManager.default.removeItem(at: folder.appendingPathComponent(name))
            }
        }
        return !folders.isEmpty && folders.allSatisfy {
            !FileManager.default.fileExists(atPath: $0.appendingPathComponent(SessionStore.fileName).path)
        }
    }

    /// Quit, forget the readback session, launch with the probe (and `env`): one home tab.
    static func freshStart(_ app: AppSession, env: [String: String] = [:]) throws {
        app.quit()
        guard forgetSession() else { throw StepError.cannotDrive("the readback profile's session could not be reset") }
        try app.launch(env: env, probe: true)
        let one = waitUntil(10) { (try? app.rowCount()) == 1 }
        let rows = one ? 1 : try app.rowCount()  // an unreachable probe is NOT READ BACK, never -1 rows
        try expect(rows == 1, "no saved session: the sidebar has \(rows) row(s), not 1 home tab")
    }

    static func pages() throws -> TestPages {
        do { return try TestPages.shared.get() } catch { throw StepError.cannotDrive("\(error)") }
    }

    /// In the selected tab: type the test page's address, Return, until its title shows.
    static func open(_ app: AppSession, page: Int) throws {
        let url = try pages().url("/page/\(page)")
        try app.act(.navigate(url), "address bar: test page \(page), Return")
        let title = TestPageContent.title(page: page)
        let shown = waitUntil(15) { (try? app.state().title) == title }
        try expect(shown, "typed \(url); after 15 s the title is \"\((try? app.state().title) ?? "")\"")
    }

    /// Test pages 1 to 3 in 3 tabs, as the user opens them: the address bar, File > New Tab.
    static func openThree(_ app: AppSession) throws {
        try open(app, page: 1)
        for page in 2...3 {
            try app.act(.newTab, "File > New Tab")
            try open(app, page: page)
        }
    }
}
