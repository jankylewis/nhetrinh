import Foundation
import NhetrinhCore

/// R39 to R43: the P7 readback (hubs/product/plan/M3_V1_RELEASE.md), tab folders, called groups since
/// P8-GROUPS-1 (nested groups: R49, `_GroupStep.swift`). Every group action is a row's menu item, pressed
/// as the user's right click reaches the outline (no pointer event, D18); the name is typed into the
/// sheet's field. A drag is not read back: "Move Tab to Group" takes the same tree move, and the drop
/// itself is unit tested (`FoldersTests.dropsIntoAFolder`, `GroupMenuTests.dropAGroup`).
enum FolderSteps {
    static let all: [Step] = [
        Step(id: "R39", name: "New Group, named work: its row appears", run: newFolder),
        Step(id: "R40", name: "2 tabs moved in: the group holds 2", run: twoTabsIn),
        Step(id: "R41", name: "collapse hides 2 rows; a relaunch keeps group, name, tabs, collapsed",
             run: collapseStays),
        Step(id: "R42", name: "Ungroup: its 2 tabs are back at the top level", run: deleteKeepsTabs),
        Step(id: "R43", name: "a version 1 session: every tab is back, the file kept once", run: VersionOneStep.run),
    ]

    static let name = "work"
    static func titles(_ pages: ClosedRange<Int>) -> [String] { pages.map(TestPageContent.title(page:)) }

    /// 3 test pages in 3 tabs, then New Group… on row 1: rows page 1 | work | page 2 | page 3.
    static func withFolder(_ app: AppSession) throws -> ProbeState {
        try ToolSteps.fresh(app)
        try LifecycleSteps.openThree(app)
        try app.act(.rowMenu(row: 0, item: "New Group…"), "row 1's menu > New Group…")
        try expect(waitUntil(5) { (try? app.state().sheetKind) == "alert" }, "New Group… showed no sheet in 5 s")
        try app.act(.sheetField(index: 0, text: name), "the sheet's name field: \(name)")
        try app.act(.sheetButton("Create"), "the sheet's Create")
        return try until(app, "the group \(name) after Create") { $0.folders == [name] }
    }

    static func newFolder(_ app: AppSession) throws -> String {
        let state = try withFolder(app)
        let rows = [titles(1...1)[0], name] + titles(2...3)
        try expect(state.rows == rows, "rows \(state.rows), not \(rows)")
        return "3 tabs; row 1's menu > New Group…, typed \(name), Create: rows \(state.rows)"
    }

    /// The group with test pages 2 and 3 moved in by their row menus.
    static func withTwoIn(_ app: AppSession) throws -> ProbeState {
        _ = try withFolder(app)
        for row in 2...3 {
            try app.act(.rowMenu(row: row, item: "Move Tab to Group > \(name)"),
                        "row \(row + 1)'s menu > Move Tab to Group")
        }
        return try until(app, "2 tabs in \(name)") { $0.folderTabs == [titles(2...3)] }
    }

    static func twoTabsIn(_ app: AppSession) throws -> String {
        let state = try withTwoIn(app)
        return "rows 3 and 4: menu > Move Tab to Group > \(name): \(name) holds \(state.folderTabs[0]); "
            + "rows \(state.rows) (a drag: unit tested only)"
    }

    static func collapseStays(_ app: AppSession) throws -> String {
        _ = try withTwoIn(app)
        try app.act(.rowMenu(row: 1, item: "Collapse Group"), "the group row's menu > Collapse Group")
        let collapsed = try until(app, "2 rows hidden") { $0.rows == [titles(1...1)[0], name] }
        try app.act(.menu(["nhetrinh", "Quit nhetrinh"]), "nhetrinh > Quit nhetrinh")
        try expect(app.waitForEnd(10), "nhetrinh > Quit nhetrinh: the app still runs after 10 s")
        try app.launch(probe: true)
        let after = try until(app, "the group after a launch") { $0.folders == [name] }
        try expect(after.rows == collapsed.rows && after.folderTabs == [titles(2...3)]
                   && after.collapsedFolders == [true], "after the launch: rows \(after.rows), folders "
                   + "\(after.folders) \(after.folderTabs), collapsed \(after.collapsedFolders)")
        return "Collapse Group: rows \(collapsed.rows); quit and launch: rows \(after.rows), \(name) holds "
            + "\(after.folderTabs[0]), collapsed"
    }

    static func deleteKeepsTabs(_ app: AppSession) throws -> String {
        _ = try withTwoIn(app)
        try app.act(.rowMenu(row: 1, item: "Ungroup"), "the group row's menu > Ungroup")
        let state = try until(app, "no group after Ungroup") { $0.folders.isEmpty }
        try expect(state.rows == titles(1...3), "after Ungroup the rows are \(state.rows)")
        return "Ungroup: no group; rows \(state.rows): its 2 tabs at the top level, none closed"
    }

    /// The state once `done` holds (10 s at most), else FAIL with the last state seen.
    static func until(_ app: AppSession, _ what: String, _ done: @escaping (ProbeState) -> Bool) throws -> ProbeState {
        var state = try app.state()
        let held = waitUntil(10) {
            state = (try? app.state()) ?? state
            return done(state)
        }
        try expect(held, "\(what): rows \(state.rows), groups \(state.groupPaths) \(state.folderTabs)")
        return state
    }
}
