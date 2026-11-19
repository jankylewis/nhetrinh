import Foundation
import NhetrinhCore

/// R27 to R30a: the P4 readback (hubs/product/plan/M2_REAL_SITES_WORK.md): find, zoom, the Settings Hub.
/// Menus are pressed as a click does (D18); the hub's controls are set as a user picks them. Every step
/// starts without the readback profile's prefs, so a level or a look of an earlier run never leaks in.
enum ToolSteps {
    static let all: [Step] = [
        Step(id: "R27", name: "Find: found, not found, Close hides the bar", run: findBar),
        Step(id: "R28", name: "Zoom In twice shows 125 %, kept for the host after a relaunch",
             run: ZoomSteps.keptPerHost),
        Step(id: "R29", name: "the search engine of the Settings Hub takes the next search", run: HubSteps.engine),
        Step(id: "R30", name: "Clear Website Data removes a page's cookie", run: HubSteps.clearData),
        Step(id: "R30a", name: "Appearance Dark: window and page dark, kept; System: the system look",
             run: HubSteps.appearance),
    ]

    /// The readback profile's prefs, removed (`prefs.json` and a kept bad file).
    @discardableResult
    static func forgetPrefs() -> Bool {
        let folders = AppSession.folders()  // its own and P9's old one (P10-PROFILE)
        for folder in folders {
            for name in [PrefsStore.fileName, PrefsStore.badFileName] {
                try? FileManager.default.removeItem(at: folder.appendingPathComponent(name))
            }
        }
        return !folders.isEmpty && folders.allSatisfy {
            !FileManager.default.fileExists(atPath: $0.appendingPathComponent(PrefsStore.fileName).path)
        }
    }

    /// No prefs, then a fresh start: one home tab. The app writes prefs only on a change, never at quit.
    static func fresh(_ app: AppSession) throws {
        app.quit()
        guard forgetPrefs() else { throw StepError.cannotDrive("the readback profile's prefs could not be reset") }
        try LifecycleSteps.freshStart(app)
    }

    /// Open `path` of the test pages in the selected tab and wait for `title`.
    @discardableResult
    static func open(_ app: AppSession, _ path: String, title: String) throws -> String {
        let url = try LifecycleSteps.pages().url(path)
        try app.act(.navigate(url), "address bar: \(path), Return")
        try SheetDriving.title(app, title, after: "typed \(url)", timeout: 15)
        return url
    }

    /// Wait until `check` holds on a fresh state; FAIL with `seen` of the last state.
    static func until(_ app: AppSession, within timeout: TimeInterval = 10, _ check: (ProbeState) -> Bool,
                      else seen: (ProbeState) -> String) throws -> ProbeState {
        var state = try app.state()
        let held = waitUntil(timeout) {
            state = (try? app.state()) ?? state
            return check(state)
        }
        try expect(held, seen(state))
        return state
    }

    static func findBar(_ app: AppSession) throws -> String {
        try fresh(app)
        try open(app, "/find", title: ToolPages.findTitle)
        try app.act(.menu(["Edit", "Find", "Find…"]), "Edit > Find > Find…")
        _ = try until(app, { $0.findShown }, else: { _ in "Edit > Find > Find…: no find bar after 10 s" })
        var seen: [String] = []
        for (word, answer) in [("Example", "found"), ("zzzz", "not found")] {
            try app.act(.find(word), "find bar: \(word), Return")
            _ = try until(app, { $0.findResult == answer }, else: { "\(word): the bar says \"\($0.findResult)\"" })
            seen.append("\"\(word)\": \(answer)")
        }
        try app.act(.button("Close"), "find bar: Close")
        _ = try until(app, { !$0.findShown }, else: { _ in "Close pressed: the find bar is still shown" })
        return "Edit > Find > Find…: the bar; " + seen.joined(separator: ", ") + "; Close: the bar is gone"
    }
}
