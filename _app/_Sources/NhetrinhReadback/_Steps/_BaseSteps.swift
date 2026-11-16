import ApplicationServices
import Foundation

/// R1 to R8: the base readback. It runs in every phase, on the installed app.
/// Each step acts as the user would and returns what it saw; it throws when the app is wrong.
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
        let window = try app.window()
        let sidebar = try app.element("nhetrinh.sidebar")
        _ = try app.element("nhetrinh.address")
        let width = Int(sidebar.frame?.width ?? 0)
        try expect(width >= 100, "the sidebar is \(width) pt wide")
        let rows = sidebar.rows.count
        try expect(rows >= 1, "the sidebar has no row")
        return "window \"\(window.title)\"; sidebar \(width) pt wide with \(rows) row(s); address bar present"
    }

    static func addressLoadsPage(_ app: AppSession) throws -> String {
        try app.navigate("example.com")
        let window = try app.window()
        let loaded = waitUntil(20) { window.title == "Example Domain" }
        let address = try app.addressText()
        try expect(loaded, "typed example.com; after 20 s the title is \"\(window.title)\", the address \"\(address)\"")
        try expect(address == "https://example.com/", "the title is right but the address bar shows \"\(address)\"")
        return "typed example.com and confirmed; title \"Example Domain\", address bar \"\(address)\""
    }

    static func wordsBecomeOneSearch(_ app: AppSession) throws -> String {
        try app.navigate("rock & roll")
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
        let before = try app.rowCount()
        let newTab = try app.menuItem(["File", "New Tab"])
        let closeTab = try app.menuItem(["File", "Close Tab"])
        try expect(newTab.shortcut == "⌘T", "New Tab has the shortcut \"\(newTab.shortcut)\", not ⌘T")
        try expect(closeTab.shortcut == "⌘W", "Close Tab has the shortcut \"\(closeTab.shortcut)\", not ⌘W")
        try newTab.press()
        let grew = waitUntil(3) { (try? app.rowCount()) == before + 1 }
        try expect(grew, "after New Tab the sidebar has \((try? app.rowCount()) ?? -1) rows, not \(before + 1)")
        try closeTab.press()
        let shrank = waitUntil(3) { (try? app.rowCount()) == before }
        try expect(shrank, "after Close Tab the sidebar has \((try? app.rowCount()) ?? -1) rows, not \(before)")
        return "File > New Tab (⌘T): rows \(before) to \(before + 1); File > Close Tab (⌘W): back to \(before)"
    }

    static func selectingRowShowsTab(_ app: AppSession) throws -> String {
        try app.navigate("example.com")
        try app.menuItem(["File", "New Tab"]).press()
        try app.navigate("example.org")
        let second = waitUntil(20) { (try? app.addressText()) == "https://example.org/" }
        try expect(second, "the new tab did not reach example.org; address \"\((try? app.addressText()) ?? "")\"")
        let rows = try app.element("nhetrinh.sidebar").rows
        try expect(rows.count >= 2, "the sidebar has \(rows.count) row(s); 2 are needed")
        try rows[rows.count - 2].set(kAXSelectedAttribute, to: kCFBooleanTrue)
        let first = waitUntil(5) { (try? app.addressText())?.contains("example.com") == true }
        try expect(first, "selected the row above; the address bar still shows \"\((try? app.addressText()) ?? "")\"")
        try rows[rows.count - 1].set(kAXSelectedAttribute, to: kCFBooleanTrue)
        let back = waitUntil(5) { (try? app.addressText()) == "https://example.org/" }
        try expect(back, "selected the last row; the address bar shows \"\((try? app.addressText()) ?? "")\"")
        return "two tabs; selecting the row above showed example.com, selecting the last row showed example.org"
    }
}
