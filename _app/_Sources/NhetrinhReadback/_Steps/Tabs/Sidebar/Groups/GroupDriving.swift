import Foundation
import NhetrinhCore

/// How R49 drives the groups: a row found by its title (tab titles and group names are unique in R49), its
/// menu pressed as the user's right click reaches the outline (D18), a name typed into the sheet's field.
/// No focus, no keys.
enum GroupDriving {
    /// Test page `page`'s title: R49's tabs.
    static func page(_ page: Int) -> String { TestPageContent.title(page: page) }

    /// The row that reads `title` now.
    static func row(_ app: AppSession, _ title: String) throws -> Int {
        let rows = try app.state().rows
        guard let row = rows.firstIndex(of: title) else { throw StepError.fail("no row \(title) in \(rows)") }
        return row
    }

    /// `item` of the menu of the row that reads `title`.
    static func press(_ app: AppSession, on title: String, _ item: String) throws {
        try app.act(.rowMenu(row: row(app, title), item: item), "\(title)'s menu > \(item)")
    }

    /// `item` on `title`'s row, then `name` typed into the sheet's field and `button` pressed.
    static func named(_ app: AppSession, on title: String, _ item: String, name: String,
                      button: String = "Create") throws {
        try press(app, on: title, item)
        try expect(waitUntil(5) { (try? app.state().sheetKind) == "alert" }, "\(item) showed no sheet in 5 s")
        try app.act(.sheetField(index: 0, text: name), "the sheet's name field: \(name)")
        try app.act(.sheetButton(button), "the sheet's \(button)")
        try sheetGone(app, after: "\(item) \(button)")
    }

    /// The sheet ends (5 s at most).
    static func sheetGone(_ app: AppSession, after what: String) throws {
        try expect(waitUntil(5) { (try? app.state().sheetKind) == "" }, "\(what): the sheet is still shown after 5 s")
    }

    /// The state once the groups read `paths` (10 s at most), else FAIL with what was seen.
    @discardableResult
    static func groups(_ app: AppSession, _ paths: [String], after what: String) throws -> ProbeState {
        try FolderSteps.until(app, "\(what): groups \(paths)") { $0.groupPaths == paths }
    }

    /// The state once the tree reads `shape` (10 s at most), else FAIL naming the field that differs.
    @discardableResult
    static func shape(_ app: AppSession, _ shape: GroupShape, after what: String) throws -> ProbeState {
        var state = try app.state()
        _ = waitUntil(10) {
            state = (try? app.state()) ?? state
            return shape.holds(state)
        }
        try shape.check(state, after: what)
        return state
    }

    /// Every tab still there, in this order (none closed, none copied).
    static func tabs(_ state: ProbeState, _ pages: ClosedRange<Int>, after what: String) throws {
        let titles = pages.map(page)
        try expect(state.tabTitles == titles, "\(what): the tabs are \(state.tabTitles), not \(titles)")
    }
}
