import Foundation
import NhetrinhCore

/// R16 to R18: the site icon in its row, a link in a background tab, Stop.
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

    static func iconInItsRow(_ app: AppSession) throws -> String {
        _ = try openTest(app, "/icon", title: TestPageContent.iconTitle)
        var state = try app.state()
        let shown = waitUntil(10) {
            state = (try? app.state()) ?? state
            return state.icons.first == true
        }
        try expect(shown, "the page links /icon.png as its icon; after 10 s the row's icon flags are \(state.icons)")
        return "a test page with <link rel=\"icon\">: row 1 shows its icon"
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
        return "the link's menu \(state.webMenu) > \(item): 2 rows \(state.rows), row 1 still selected at \(url)"
    }

    static func stopEndsLoading(_ app: AppSession) throws -> String {
        _ = try openTest(app, "/slow", title: nil)
        var state = try app.state()
        let loading = waitUntil(10) {
            state = (try? app.state()) ?? state
            return state.loading && state.reloadButton == "Stop"
        }
        try expect(loading, "the slow page: loading \(state.loading), the button reads \"\(state.reloadButton)\"")
        try app.act(.button("Stop"), "toolbar: Stop")
        let stopped = waitUntil(5) {
            state = (try? app.state()) ?? state
            return !state.loading && state.reloadButton == "Reload"
        }
        try expect(stopped, "after Stop: loading \(state.loading), the button reads \"\(state.reloadButton)\"")
        return "a page that answers after 30 s: loading, the button read Stop; "
            + "Stop pressed: loading ended, it reads Reload"
    }
}
