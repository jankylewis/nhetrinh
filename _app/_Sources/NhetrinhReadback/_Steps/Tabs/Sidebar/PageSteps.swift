import Foundation
import NhetrinhCore

/// R16 to R18: the site icon in its row, a link in a background tab (menu and ⌘-click), Stop.
enum PageSteps {
    /// A fresh start, then `path` of the test pages typed in the address bar; waits for `title` if given.
    private static func openTest(_ app: AppSession, _ path: String, title: String?) throws -> String {
        let url = try LifecycleSteps.pages().url(path)
        try LifecycleSteps.freshStart(app)
        try app.act(.navigate(url), "address bar: \(path), Return")
        guard let title else { return url }
        let shown = waitUntil(15) { (try? app.state().title) == title }
        try expect(shown, "typed \(url); after 15 s the title is \"\((try? app.state().title) ?? "")\"")
        return url
    }

    /// The icon the row view shows (not the tab's data), through three pages in one tab: each changes
    /// what the row shows, so an icon left over from the page before cannot pass a check.
    static func iconInItsRow(_ app: AppSession) throws -> String {
        _ = try openTest(app, "/icon", title: TestPageContent.iconTitle)
        try rowIcon(app, shows: true, "a page whose <link rel=\"icon\"> is /icon.png")
        try typeTest(app, "/noicon", title: TestPageContent.noIconTitle)
        try rowIcon(app, shows: false, "a page whose <link rel=\"icon\"> answers 404")
        try typeTest(app, "/page/1", title: TestPageContent.title(page: 1))
        try rowIcon(app, shows: true, "a page with no <link rel=\"icon\">, its origin's /favicon.ico")
        return "row 1 shows the icon of <link rel=\"icon\">, the globe when that icon answers 404, "
            + "and /favicon.ico for a page with no link"
    }

    /// In the same tab: `path` typed in the address bar, until `title` shows.
    private static func typeTest(_ app: AppSession, _ path: String, title: String) throws {
        let url = try LifecycleSteps.pages().url(path)
        try app.act(.navigate(url), "address bar: \(path), Return")
        let shown = waitUntil(15) { (try? app.state().title) == title }
        try expect(shown, "typed \(url); after 15 s the title is \"\((try? app.state().title) ?? "")\"")
    }

    /// Row 1's view shows a site icon (`shows`) or the globe, within 10 s.
    private static func rowIcon(_ app: AppSession, shows: Bool, _ page: String) throws {
        var state = try app.state()
        let seen = waitUntil(10) {
            state = (try? app.state()) ?? state
            return state.icons.first == shows
        }
        try expect(seen, "\(page): after 10 s row 1 shows \(state.icons.first == true ? "an icon" : "the globe")")
    }

    /// The link's menu is WebKit's own: if it does not open, the step is NOT READ BACK, never PASS.
    static func linkInBackground(_ app: AppSession) throws -> String {
        let url = try openTest(app, "/links", title: TestPageContent.linksTitle)
        let item = "Open Link in New Tab"
        try app.act(.linkMenu(item: item), "the link's menu > \(item)")
        var state = try app.state()
        let opened = waitUntil(10) {
            state = (try? app.state()) ?? state
            return state.rows.count == 2
        }
        guard opened || !state.webMenu.isEmpty else {
            throw StepError.cannotDrive("the link's menu did not open (no menu seen in 10 s): not read back")
        }
        try expect(state.webMenu.contains(item), "the link's menu reads \(state.webMenu), with no \(item)")
        try expect(opened, "pressed \(item): the sidebar has \(state.rows.count) row(s), not 2")
        try expect(state.selected == 0 && state.address == url,
                   "row \((state.selected ?? -1) + 1) is selected at \"\(state.address)\"; row 1 at \(url) expected")
        let click = try commandClick(app, url: url)
        return "the link's menu \(state.webMenu) > \(item): 2 rows \(state.rows), row 1 still selected at \(url); "
            + click
    }

    /// A ⌘-click on the link: one more row, the page stays. No row and no navigation: the click did not
    /// reach the page, NOT READ BACK. A navigation of the page itself: FAIL.
    private static func commandClick(_ app: AppSession, url: String) throws -> String {
        try app.act(.commandClickLink, "⌘-click on the link")
        var state = try app.state()
        let opened = waitUntil(10) {
            state = (try? app.state()) ?? state
            return state.rows.count == 3 || state.address != url
        }
        guard opened else { throw StepError.cannotDrive("the ⌘-click did not reach the page in 10 s: not read back") }
        try expect(state.address == url && state.selected == 0,
                   "after the ⌘-click row \((state.selected ?? -1) + 1) shows \"\(state.address)\", not \(url)")
        try expect(state.rows.count == 3, "after the ⌘-click the sidebar has \(state.rows.count) rows, not 3")
        return "⌘-click on the link: 3 rows, row 1 still selected"
    }

    static func stopEndsLoading(_ app: AppSession) throws -> String {
        _ = try openTest(app, "/slow", title: nil)
        var state = try app.state()
        let loading = waitUntil(10) {
            state = (try? app.state()) ?? state
            return state.loading && state.reloadButton == "Stop" && state.progressShown
        }
        try expect(loading, "the slow page: loading \(state.loading), the button reads \"\(state.reloadButton)\", "
                   + "progress line shown \(state.progressShown)")
        try app.act(.button("Stop"), "toolbar: Stop")
        let stopped = waitUntil(5) {
            state = (try? app.state()) ?? state
            return !state.loading && state.reloadButton == "Reload" && !state.progressShown
        }
        try expect(stopped, "after Stop: loading \(state.loading), the button reads \"\(state.reloadButton)\", "
                   + "progress line shown \(state.progressShown)")
        return "a page that answers after 30 s: loading, the button read Stop, the progress line shown; "
            + "Stop pressed: loading ended, it reads Reload, the line is gone"
    }
}
