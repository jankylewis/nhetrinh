import Foundation
import NhetrinhCore

/// What the P3 steps share: a click in the page, the window's sheet waited for, read and answered,
/// and the page's title waited for (each test page writes what happened into its title).
enum SheetDriving {
    /// Click `selector` in the selected page, as a left click; `what` names it in the verdict.
    static func click(_ app: AppSession, _ selector: String, _ what: String) throws {
        try app.act(.click(selector), "click \(what) (\(selector))")
    }

    /// The state once a sheet of `kind` is shown whose text holds `text` ("" any), in `timeout` s.
    static func sheet(_ app: AppSession, kind: String = "alert", text: String = "", after shown: Int = -1,
                      timeout: TimeInterval = 10) throws -> ProbeState {
        var state = try app.state()
        let seen = waitUntil(timeout) {
            state = (try? app.state()) ?? state
            return state.sheetKind == kind && (text.isEmpty || state.sheet.contains(text)) && state.sheetsShown > shown
        }
        try expect(seen, "no \(kind) sheet with \"\(text)\" after \(Int(timeout)) s; "
            + "the sheet is \"\(state.sheetKind)\" \"\(state.sheet)\", the title \"\(state.title)\"")
        return state
    }

    static func press(_ app: AppSession, _ label: String) throws {
        try app.act(.sheetButton(label), "the sheet's \(label)")
    }

    /// The state once no sheet is shown, or FAIL after `timeout` s.
    static func gone(_ app: AppSession, after action: String, timeout: TimeInterval = 5) throws -> ProbeState {
        var state = try app.state()
        let closed = waitUntil(timeout) {
            state = (try? app.state()) ?? state
            return state.sheetKind.isEmpty
        }
        try expect(closed, "\(action): the \(state.sheetKind) sheet is still shown after \(Int(timeout)) s")
        return state
    }

    /// The title once it is `title`, or FAIL with the last title seen.
    @discardableResult
    static func title(_ app: AppSession, _ title: String, after action: String,
                      timeout: TimeInterval = 10) throws -> ProbeState {
        var state = try app.state()
        let shown = waitUntil(timeout) {
            state = (try? app.state()) ?? state
            return state.title == title
        }
        try expect(shown, "\(action): the page's title is \"\(state.title)\", not \"\(title)\"")
        return state
    }
}
