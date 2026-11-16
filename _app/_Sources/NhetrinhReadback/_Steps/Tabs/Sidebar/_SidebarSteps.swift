import Foundation
import NhetrinhCore

/// R13 to R18: the P2 readback (hubs/product/plan/M1_DAILY_DRIVER.md), the sidebar and the page chrome.
/// Every page is the readback's own (`TestPages`, 127.0.0.1); each step starts from one home tab.
/// Hover and drag stay the user's way (no system events, D18). The row's menu and a middle click are sent
/// to the table as the window delivers a click (its hit test included); the Tabs menu is pressed.
enum SidebarSteps {
    static let all: [Step] = [
        Step(id: "R13", name: "a row's menu and a middle click close that row", run: rowMenuCloses),
        Step(id: "R14", name: "Move Tab Up moves the row, and it stays after a relaunch", run: moveTabUpStays),
        Step(id: "R15", name: "Reopen Closed Tab brings a middle row back in its place", run: reopenBringsItBack),
        Step(id: "R16", name: "a site with an icon shows it in its row", run: PageSteps.iconInItsRow),
        Step(id: "R17", name: "Open Link in New Tab opens a background tab", run: PageSteps.linkInBackground),
        Step(id: "R18", name: "Stop ends the loading and the button is Reload again", run: PageSteps.stopEndsLoading),
    ]

    private static func three(_ app: AppSession) throws -> ProbeState {
        try LifecycleSteps.freshStart(app)
        try LifecycleSteps.openThree(app)
        return try app.state()
    }

    /// The state once the sidebar has `count` rows (5 s at most), else the last state seen.
    private static func rows(_ app: AppSession, _ count: Int) throws -> ProbeState {
        var state = try app.state()
        waitUntil(5) {
            state = (try? app.state()) ?? state
            return state.rows.count == count
        }
        return state
    }

    static func rowMenuCloses(_ app: AppSession) throws -> String {
        let before = try three(app)
        try app.act(.rowMenu(row: 0, item: "Close Tab"), "a right click on row 1, its menu > Close Tab")
        let menu = try rows(app, 2)
        try expect(menu.rows == Array(before.rows.dropFirst()),
                   "row 1's menu > Close Tab: rows \(before.rows) became \(menu.rows)")
        try expect(menu.title == before.title, "the window shows \"\(menu.title)\", not \"\(before.title)\"")
        try app.act(.middleClick(row: 0), "a middle click on row 1")
        let middle = try rows(app, 1)
        try expect(middle.rows == Array(before.rows.dropFirst(2)),
                   "a middle click on row 1: rows \(menu.rows) became \(middle.rows)")
        try expect(middle.title == before.title, "the window shows \"\(middle.title)\", not \"\(before.title)\"")
        return "3 rows; row 1's menu > Close Tab: \(menu.rows); a middle click on row 1: \(middle.rows); "
            + "the selected tab kept"
    }

    static func moveTabUpStays(_ app: AppSession) throws -> String {
        _ = try three(app)
        try app.act(.select(2), "select sidebar row 3")
        for _ in 1...2 { try app.act(.menu(["Tabs", "Move Tab Up"]), "Tabs > Move Tab Up") }
        let third = TestPageContent.title(page: 3)
        var state = try app.state()
        waitUntil(5) {
            state = (try? app.state()) ?? state
            return state.rows.first == third
        }
        let row = (state.selected ?? -1) + 1
        try expect(state.rows.first == third && state.selected == 0,
                   "Tabs > Move Tab Up twice from row 3: rows \(state.rows), row \(row) selected")
        Thread.sleep(forTimeInterval: 3)  // the app saves 2 s after a tab change
        try app.act(.menu(["nhetrinh", "Quit nhetrinh"]), "nhetrinh > Quit nhetrinh")
        try expect(app.waitForEnd(10), "nhetrinh > Quit nhetrinh: the app still runs after 10 s")
        try app.launch(probe: true)
        let after = try LifecycleSteps.restored(app, rows: state.rows.count)
        try expect(after.rows == state.rows, "after the relaunch the rows are \(after.rows), not \(state.rows)")
        return "row 3, Tabs > Move Tab Up twice: it is row 1 and selected; after Quit and a launch: \(after.rows)"
    }

    static func reopenBringsItBack(_ app: AppSession) throws -> String {
        let before = try three(app)
        let second = try LifecycleSteps.pages().url("/page/2")
        try app.act(.select(1), "select sidebar row 2")
        try app.act(.closeTab, "File > Close Tab")
        try expect(waitUntil(5) { (try? app.rowCount()) == 2 }, "File > Close Tab: the rows are not 2")
        try app.act(.menu(["File", "Reopen Closed Tab"]), "File > Reopen Closed Tab")
        var state = try app.state()
        let back = waitUntil(15) {
            state = (try? app.state()) ?? state
            return state.rows == before.rows && state.address == second
        }
        try expect(back, "File > Reopen Closed Tab: rows \(state.rows), address \"\(state.address)\"")
        try expect(state.selected == 1, "the reopened tab is row 2, but row \((state.selected ?? -1) + 1) is selected")
        return "row 2 of 3 selected, File > Close Tab, File > Reopen Closed Tab: rows \(state.rows), "
            + "row 2 selected at \(second)"
    }
}
