import Foundation
import NhetrinhCore

/// R50 (P8-SIDE-1, headmate request): the Settings Hub's Sidebar position set to Right, then Left, as a user
/// picks it (the probe's `setting`, as R29). On each side, with the sidebar shown, hidden by the toolbar's
/// toggle and shown again: the sidebar on its side of the web view with no overlap, the toolbar's buttons
/// clear of the traffic lights (R48's reading), the toggle drawn on that side. The start state is put back.
/// No focus, no keys.
enum SideStep {
    static let step = Step(id: "R50", name: "the sidebar sits right, then left, never over the web view; "
                           + "the toolbar clears the traffic lights", run: run)
    static let control = "Sidebar position"

    /// What a reader sees wrong with the window on `side`, the sidebar `shown` or hidden. Empty: right.
    static func wrong(_ state: ProbeState, side: SidebarSide, shown: Bool) -> [String] {
        var seen: [String] = []
        if state.sidebarSide != side.rawValue { seen.append("the side reads \"\(state.sidebarSide)\"") }
        if state.toggleSymbol != side.symbol { seen.append("the toggle shows \"\(state.toggleSymbol)\"") }
        seen += ToggleStep.wrong(state)
        let (bar, web) = (state.sidebarFrame, state.webFrame)
        guard shown else { return seen + (bar.isEmpty ? [] : ["hidden, yet the sidebar reads \(bar)"]) }
        guard bar.count == 4, web.count == 4 else { return seen + ["the sidebar's or the web view's frame: not read"] }
        let span = { (frame: [Double]) in "x \(Int(frame[0])) to \(Int(frame[0] + frame[2]))" }
        if SidebarLayout.overlap(bar, web) {
            seen.append("the sidebar (\(span(bar))) overlaps the web view (\(span(web)))")
        } else if (side == .right) != (bar[0] > web[0]) {
            seen.append("the sidebar (\(span(bar))) is not \(side.rawValue) of the web view (\(span(web)))")
        }
        return seen
    }

    static func run(_ app: AppSession) throws -> String {
        let start = try app.state()  // an unreachable probe is NOT READ BACK
        let (shownAtStart, sideAtStart) = (start.sidebarWidth > 0, SidebarSide(rawValue: start.sidebarSide) ?? .left)
        try HubSteps.openHub(app)
        if !shownAtStart { try ToggleStep.sidebar(app, shown: true, by: .button("Toggle Sidebar")) }
        var seen: [String] = []
        for side in [SidebarSide.right, .left] {
            try choose(app, side)
            let shown = try read(app, side, shown: true)
            try ToggleStep.sidebar(app, shown: false, by: .button("Toggle Sidebar"))
            _ = try read(app, side, shown: false)
            try ToggleStep.sidebar(app, shown: true, by: .button("Toggle Sidebar"))
            _ = try read(app, side, shown: true)
            seen.append("\(side.title): sidebar x \(Int(shown.sidebarFrame[0])), web view x \(Int(shown.webFrame[0])) "
                        + "to \(Int(shown.webFrame[0] + shown.webFrame[2])), toggle \(shown.toggleSymbol)")
        }
        if sideAtStart != .left { try choose(app, sideAtStart) }
        if !shownAtStart { try ToggleStep.sidebar(app, shown: false, by: .button("Toggle Sidebar")) }
        return "Settings Hub > \(control): \(seen.joined(separator: "; ")); on each side shown, hidden and shown "
            + "again: no overlap, the toolbar clear of the traffic lights; start state put back"
    }

    private static func choose(_ app: AppSession, _ side: SidebarSide) throws {
        try app.act(.setting(name: control, value: side.title), "Settings Hub: \(control) \(side.title)")
        waitUntil(5) { (try? app.state())?.sidebarSide == side.rawValue }
        let read = try app.state().sidebarSide
        try expect(read == side.rawValue, "\(control) \(side.title): after 5 s the side reads \"\(read)\"")
    }

    /// The state once nothing is wrong (5 s at most, a slide ends); else what is wrong.
    private static func read(_ app: AppSession, _ side: SidebarSide, shown: Bool) throws -> ProbeState {
        waitUntil(5) { (try? app.state()).map { wrong($0, side: side, shown: shown).isEmpty } == true }
        let state = try app.state()
        let wrong = wrong(state, side: side, shown: shown)
        try expect(wrong.isEmpty, "\(side.title), sidebar \(shown ? "shown" : "hidden"): "
                   + wrong.joined(separator: "; "))
        return state
    }
}
