import Foundation
import NhetrinhCore

/// R28: zoom per host, kept across a relaunch. 127.0.0.1 and localhost are two hosts of one server.
enum ZoomSteps {
    static func keptPerHost(_ app: AppSession) throws -> String {
        try ToolSteps.fresh(app)
        let title = TestPageContent.title(page: 1)
        try ToolSteps.open(app, "/page/1", title: title)
        let badge = try app.state().zoomBadge
        try expect(badge.isEmpty, "a new host shows the badge \"\(badge)\"")
        for _ in 1...2 { try app.act(.menu(["View", "Zoom In"]), "View > Zoom In") }
        _ = try ToolSteps.until(app, { $0.zoomBadge == "125 %" }, else: {
            "View > Zoom In twice: the badge reads \"\($0.zoomBadge)\", not 125 %"
        })
        try app.act(.menu(["nhetrinh", "Quit nhetrinh"]), "nhetrinh > Quit nhetrinh")
        try expect(app.waitForEnd(10), "nhetrinh > Quit nhetrinh: the app still runs after 10 s")
        try app.launch(probe: true)
        _ = try ToolSteps.until(app, within: 15, { $0.title == title && $0.zoomBadge == "125 %" }, else: {
            "after the relaunch the page \"\($0.title)\" shows the badge \"\($0.zoomBadge)\", not 125 %"
        })
        let other = try LifecycleSteps.pages().url("/page/2").replacingOccurrences(of: "127.0.0.1", with: "localhost")
        try app.act(.navigate(other), "address bar: test page 2 on localhost, Return")
        let second = TestPageContent.title(page: 2)
        _ = try ToolSteps.until(app, within: 15, { $0.title == second && $0.zoomBadge.isEmpty }, else: {
            "another host (localhost): the page \"\($0.title)\" shows the badge \"\($0.zoomBadge)\""
        })
        return "127.0.0.1, View > Zoom In twice: the badge reads 125 %; after Quit and a launch: 125 % on "
            + "127.0.0.1; localhost: no badge (100 %)"
    }
}
