import Foundation
import NhetrinhCore

/// R49 (P8-GROUPS-1, headmate request): nested groups, 4 levels. Through the probe (D23), every action a
/// row's menu item, no focus, no keys, no drag (D18; a drop is unit tested). Local test pages only, 5 tabs,
/// loaded one at a time. Builds Work > FE > PRs > Feedback entry with a tab at each level, reads a 5th
/// level refused with its reason, renames PRs, moves it to the top level and back, ungroups FE (its items
/// move up, no tab closes), closes Feedback entry and reopens it, relaunches and reads the same tree. The
/// start state (one home tab) is put back.
enum GroupStep {
    static let step = Step(id: "R49", name: "groups 4 levels deep: made, 5th refused, renamed, moved, ungrouped, "
                           + "closed and reopened, kept by a relaunch", run: run)
    static func run(_ app: AppSession) throws -> String {
        try ToolSteps.fresh(app)
        try LifecycleSteps.open(app, page: 1)
        for page in 2...5 {
            try app.act(.newTab, "File > New Tab")
            try LifecycleSteps.open(app, page: page)
        }
        let said = [try build(app), try refuseFifth(app), try renameAndMove(app), try ungroupFE(app),
                    try closeAndReopen(app), try relaunch(app)]
        try LifecycleSteps.freshStart(app)
        return said.joined(separator: "; ") + "; start state put back (one home tab)"
    }

    /// New Group…, Move Tab to Group, New Group Inside… twice, New Group from Selected Tab….
    static func build(_ app: AppSession) throws -> String {
        let page = GroupDriving.page
        try GroupDriving.named(app, on: page(1), "New Group…", name: "Work")
        try GroupDriving.press(app, on: page(2), "Move Tab to Group > Work")
        try GroupDriving.named(app, on: "Work", "New Group Inside…", name: "FE")
        try GroupDriving.press(app, on: page(3), "Move Tab to Group > Work > FE")
        try GroupDriving.named(app, on: "FE", "New Group Inside…", name: "PRs")
        for tab in 4...5 { try GroupDriving.press(app, on: page(tab), "Move Tab to Group > Work > FE > PRs") }
        try GroupDriving.named(app, on: page(5), "New Group from Selected Tab…", name: "Feedback entry")
        let state = try GroupDriving.shape(app, .built, after: "the tree built")
        return "built \(state.groupPaths.last ?? ""): rows at levels \(state.rowLevels), tab counts "
            + "\(state.groupCounts)"
    }

    static func refuseFifth(_ app: AppSession) throws -> String {
        try GroupDriving.press(app, on: "Feedback entry", "New Group Inside…")
        let reason = TreeFailure.tooDeep.reason
        let held = waitUntil(5) { (try? app.state()).map { $0.sheet.contains(reason) } == true }
        let state = try app.state()
        try expect(held && state.groupRefusal == reason, "a 5th level: sheet \"\(state.sheet)\", reason "
                   + "\"\(state.groupRefusal)\", not \"\(reason)\"")
        try app.act(.sheetButton("OK"), "the sheet's OK")
        try GroupDriving.sheetGone(app, after: "OK")
        try GroupDriving.shape(app, .built, after: "the refused 5th level")
        return "Feedback entry > New Group Inside…: refused, \"\(reason)\""
    }

    static func renameAndMove(_ app: AppSession) throws -> String {
        try GroupDriving.named(app, on: "PRs", "Rename Group…", name: "Pull requests", button: "Rename")
        try GroupDriving.shape(app, .renamed, after: "Rename Group…")
        try GroupDriving.press(app, on: "Pull requests", "Move Group to > Top Level")
        let top = try GroupDriving.shape(app, .atTop, after: "Move Group to > Top Level")
        try GroupDriving.press(app, on: "Pull requests", "Move Group to > Work > FE")
        let back = try GroupDriving.shape(app, .renamed, after: "Move Group to > Work > FE")
        try GroupDriving.tabs(back, 1...5, after: "the moves")
        return "PRs renamed Pull requests; moved to the top level (\(top.groupPaths)) and back into Work > FE"
    }

    static func ungroupFE(_ app: AppSession) throws -> String {
        try GroupDriving.press(app, on: "FE", "Ungroup")
        let state = try GroupDriving.shape(app, .ungrouped, after: "Ungroup FE")
        try GroupDriving.tabs(state, 1...5, after: "Ungroup FE")
        return "FE ungrouped: \(state.groupPaths), tab counts \(state.groupCounts), all 5 tabs kept"
    }

    static func closeAndReopen(_ app: AppSession) throws -> String {
        try GroupDriving.press(app, on: "Feedback entry", "Close Group…")
        let asked = waitUntil(5) { (try? app.state()).map { $0.sheet.contains("and its 1 tab?") } == true }
        try expect(asked, "Close Group…: the sheet reads \"\((try? app.state().sheet) ?? "")\"")
        try app.act(.sheetButton("Close"), "the sheet's Close")
        let closed = try GroupDriving.shape(app, .closed, after: "Close Group…")
        try GroupDriving.tabs(closed, 1...4, after: "Close Group…")
        try app.act(.menu(["File", "Reopen Closed Tab"]), "File > Reopen Closed Tab")
        let back = try GroupDriving.shape(app, .ungrouped, after: "Reopen Closed Tab")
        try GroupDriving.tabs(back, 1...5, after: "Reopen Closed Tab")
        return "Close Group… asked about 1 tab, closed it; Reopen Closed Tab brought Feedback entry back "
            + "with it, inside Pull requests (tab counts \(back.groupCounts))"
    }

    static func relaunch(_ app: AppSession) throws -> String {
        let before = try app.state()
        try app.act(.menu(["nhetrinh", "Quit nhetrinh"]), "nhetrinh > Quit nhetrinh")
        try expect(app.waitForEnd(10), "nhetrinh > Quit nhetrinh: the app still runs after 10 s")
        try app.launch(probe: true)
        let after = try GroupDriving.groups(app, before.groupPaths, after: "the launch")
        try expect(after.rows == before.rows && after.folderTabs == before.folderTabs
                   && after.collapsedFolders == before.collapsedFolders && after.tabTitles == before.tabTitles,
                   "after the launch: rows \(after.rows), not \(before.rows)")
        return "quit and launch: the same \(after.groupPaths.count) groups and \(after.rows.count) rows"
    }
}
