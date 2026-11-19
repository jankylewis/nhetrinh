import Foundation
import NhetrinhCore

/// R54 (P11-HISTORY, D30): the address bar's history, as a user meets it. With the readback profile's history
/// removed (the app quit; only that profile's folder, never the user's), two test pages are visited, then a
/// third; part of the first one's title typed in the address bar shows it as the dropdown's first row; ↓ chooses
/// it (Return alone opens what was typed, as before), Return opens it. The test pages are 127.0.0.1's: the app
/// keeps them only in the readback profile (`HistoryRules`).
enum HistoryStep {
    static let step = Step(id: "R54", name: "a visited page's title typed in the address bar: the dropdown shows "
        + "it first, Return opens it", run: run)
    static let typed = "history alp"

    static func run(_ app: AppSession) throws -> String {
        app.quit()
        guard forgetHistory() else { throw StepError.cannotDrive("the readback profile's history could not be reset") }
        try ToolSteps.fresh(app)
        let wanted = ToolPages.historyPages["/history/alpha"] ?? ""
        try ToolSteps.open(app, "/history/alpha", title: wanted)
        try ToolSteps.open(app, "/history/beta", title: ToolPages.historyPages["/history/beta"] ?? "")
        try ToolSteps.open(app, "/find", title: ToolPages.findTitle)
        try app.act(.type(typed), "address bar: typed \"\(typed)\"")
        let shown = try ToolSteps.until(app, { failure(rows: $0.suggestions, wanted: wanted) == nil }, else: {
            failure(rows: $0.suggestions, wanted: wanted) ?? ""
        })
        try app.act(.key("Down"), "address bar: ↓")
        _ = try ToolSteps.until(app, { $0.suggestionChosen == 0 }, else: {
            "↓: the chosen row is \($0.suggestionChosen.map(String.init) ?? "none"), not the first"
        })
        try app.act(.key("Return"), "address bar: Return")
        _ = try ToolSteps.until(app, within: 15, { $0.title == wanted }, else: {
            "Return on the first row: the page reads \"\($0.title)\", not \"\(wanted)\""
        })
        return "visited /history/alpha, /history/beta, /find; typed \"\(typed)\": \(shown.suggestions.count) "
            + "row(s), the first \"\(shown.suggestions.first ?? "")\"; ↓, Return: the page read \"\(wanted)\""
    }

    /// Why the dropdown's rows fail R54, or nil: the first row is the page titled `wanted`.
    static func failure(rows: [String], wanted: String) -> String? {
        guard let first = rows.first else { return "the dropdown shows no row" }
        return first.hasPrefix(wanted + " — ") ? nil : "the dropdown's first row is \"\(first)\", not \"\(wanted)\""
    }

    /// The readback profile's history files removed (the app is quit first). Never another profile's folder.
    @discardableResult
    static func forgetHistory() -> Bool {
        let files = AppSession.folders().map { $0.appendingPathComponent(HistoryStore.fileName) }  // P10: both
        guard !files.isEmpty else { return false }
        for file in files {
            for suffix in ["", "-wal", "-shm"] { try? FileManager.default.removeItem(atPath: file.path + suffix) }
        }
        return files.allSatisfy { !FileManager.default.fileExists(atPath: $0.path) }
    }
}
