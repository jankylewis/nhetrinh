import Foundation
import NhetrinhCore

/// R1 to R8: the base readback. It runs in every phase, on the installed app.
/// Each step acts as the user would and returns what it saw; it throws when the app is wrong.
/// R1, R3-R7 read and act through the app's readback probe (D23): the menu item, the address field
/// and the sidebar row the user would use, with no Accessibility permission. R2 reads the Dock.
enum BaseSteps {
    static let all: [Step] = [
        Step(id: "R1", name: "the window opens with the sidebar and the address bar", run: windowOpens),
        Step(id: "R2", name: "the Dock icon has no tile", run: SystemSteps.dockIconHasNoTile),
        Step(id: "R3", name: "an address loads its page", run: addressLoadsPage),
        Step(id: "R4", name: "words in the address bar become one search", run: wordsBecomeOneSearch),
        Step(id: "R5", name: "New Tab and Close Tab change the sidebar", run: newAndCloseTab),
        Step(id: "R6", name: "selecting another row shows that tab", run: selectingRowShowsTab),
        Step(id: "R7", name: "tabs that were not opened cost no page process",
             run: SystemSteps.unopenedTabsCostNothing),
        Step(id: "R8", name: "the lightness budget holds", run: SystemSteps.budgetHolds),
    ]

    static func windowOpens(_ app: AppSession) throws -> String {
        var state = try app.state()
        waitUntil(10) {
            state = (try? app.state()) ?? state
            return state.windowShown && !state.rows.isEmpty
        }
        try expect(state.windowShown, "no window shown after 10 s")
        let width = Int(state.sidebarWidth)
        try expect(width >= 100, "the sidebar is \(width) pt wide")
        try expect(!state.rows.isEmpty, "the sidebar has no row")
        try expect(state.addressShown, "the address bar is not shown")
        return "window \"\(state.title)\"; sidebar \(width) pt wide with \(state.rows.count) row(s); address bar shown"
    }

    static func addressLoadsPage(_ app: AppSession) throws -> String {
        try app.act(.navigate("example.com"), "address bar: example.com, Return")
        var state = try app.state()
        let loaded = waitUntil(20) {
            state = (try? app.state()) ?? state
            return state.title == "Example Domain"
        }
        let seen = "the title is \"\(state.title)\", the address \"\(state.address)\""
        try expect(loaded, "typed example.com; after 20 s \(seen)")
        try expect(state.address == "https://example.com/",
                   "the title is right but the address bar shows \"\(state.address)\"")
        return "typed example.com and confirmed; title \"Example Domain\", address bar \"\(state.address)\""
    }

    static func wordsBecomeOneSearch(_ app: AppSession) throws -> String {
        try app.act(.navigate("rock & roll"), "address bar: rock & roll, Return")
        let wanted = "q=rock%20%26%20roll"
        var seen = ""
        // The first address the bar shows is the request itself, before any redirect of the site.
        let found = waitUntil(10, every: 0.05) {
            seen = (try? app.addressText()) ?? seen
            return seen.contains(wanted)
        }
        try expect(found, "typed `rock & roll`; the address bar never held \(wanted); last value \"\(seen)\"")
        return "typed `rock & roll` and confirmed; the address bar held \"\(seen)\""
    }

    static func newAndCloseTab(_ app: AppSession) throws -> String {
        let state = try app.state()
        let before = state.rows.count
        let newTab = state.shortcuts["File > New Tab"] ?? "none"
        let closeTab = state.shortcuts["File > Close Tab"] ?? "none"
        try expect(newTab == "⌘T", "New Tab has the shortcut \"\(newTab)\", not ⌘T")
        try expect(closeTab == "⌘W", "Close Tab has the shortcut \"\(closeTab)\", not ⌘W")
        try app.act(.newTab, "File > New Tab")
        let grew = waitUntil(3) { (try? app.rowCount()) == before + 1 }
        try expect(grew, "after New Tab the sidebar has \((try? app.rowCount()) ?? -1) rows, not \(before + 1)")
        try app.act(.closeTab, "File > Close Tab")
        let shrank = waitUntil(3) { (try? app.rowCount()) == before }
        try expect(shrank, "after Close Tab the sidebar has \((try? app.rowCount()) ?? -1) rows, not \(before)")
        return "File > New Tab (⌘T): rows \(before) to \(before + 1); File > Close Tab (⌘W): back to \(before)"
    }

    static func selectingRowShowsTab(_ app: AppSession) throws -> String {
        try app.act(.navigate("example.com"), "address bar: example.com, Return")
        try app.act(.newTab, "File > New Tab")
        try app.act(.navigate("example.org"), "address bar: example.org, Return")
        let second = waitUntil(20) { (try? app.addressText()) == "https://example.org/" }
        try expect(second, "the new tab did not reach example.org; address \"\((try? app.addressText()) ?? "")\"")
        try app.selectRow(fromEnd: 1)
        let first = waitUntil(5) { (try? app.addressText())?.contains("example.com") == true }
        try expect(first, "selected the row above; the address bar still shows \"\((try? app.addressText()) ?? "")\"")
        try app.selectRow(fromEnd: 0)
        let back = waitUntil(5) { (try? app.addressText()) == "https://example.org/" }
        try expect(back, "selected the last row; the address bar shows \"\((try? app.addressText()) ?? "")\"")
        return "two tabs; selecting the row above showed example.com, selecting the last row showed example.org"
    }
}
