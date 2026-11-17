import Foundation
import NhetrinhCore

/// R48 (P8-CHROME-1, NT-BUG-018): with the sidebar hidden, the toolbar's Toggle Sidebar and Back buttons
/// start right of the traffic lights and do not overlap; the toggle shows the sidebar, then hides it. The
/// start state is put back. Through the probe (D23): View > Toggle Sidebar and the toolbar button are each
/// performed as a click; no focus, no keys.
enum ToggleStep {
    static let step = Step(id: "R48", name: "sidebar hidden: the toolbar clears the traffic lights; its toggle works",
                           run: run)
    /// Left to right, as the toolbar shows them.
    static let buttons = ["Toggle Sidebar", "Back"]

    /// What a reader sees wrong: a button not read, one that starts left of the zoom button's right edge, or
    /// one that starts left of the button before it ends. Empty: clear.
    static func wrong(_ state: ProbeState) -> [String] {
        guard let lights = state.zoomMaxX else { return ["the zoom button: not read"] }
        var seen: [String] = []
        var (edge, previous) = (lights, "the zoom button")
        for name in buttons {
            guard let frame = state.toolbarFrames[name], frame.count == 4 else {
                seen.append("\(name): not read")
                continue
            }
            if frame[0] < edge {
                seen.append("\(name) starts at x \(Int(frame[0])), left of \(previous)'s right edge \(Int(edge))")
            }
            if frame[0] + frame[2] > edge { (edge, previous) = (frame[0] + frame[2], name) }
        }
        return seen
    }

    static func run(_ app: AppSession) throws -> String {
        let shownAtStart = try app.state().sidebarWidth > 0  // an unreachable probe is NOT READ BACK
        if shownAtStart { try sidebar(app, shown: false, by: .menu(["View", "Toggle Sidebar"])) }
        waitUntil(2) { (try? app.state()).map { wrong($0).isEmpty } == true }  // the slide ends
        let hidden = try app.state()
        try expect(wrong(hidden).isEmpty, "sidebar hidden: \(wrong(hidden).joined(separator: "; "))")
        try sidebar(app, shown: true, by: .button("Toggle Sidebar"))
        try sidebar(app, shown: false, by: .button("Toggle Sidebar"))
        if shownAtStart { try sidebar(app, shown: true, by: .menu(["View", "Toggle Sidebar"])) }
        let place = buttons.map { "\($0) at x \(Int(hidden.toolbarFrames[$0]?[0] ?? 0))" }.joined(separator: ", ")
        return "sidebar hidden: zoom button ends at x \(Int(hidden.zoomMaxX ?? 0)), \(place); "
            + "the toolbar's toggle showed the sidebar, then hid it; start state put back"
    }

    /// `request` performed, then the sidebar read until it is shown (or hidden), 5 s at most (R48, R50).
    static func sidebar(_ app: AppSession, shown: Bool, by request: ProbeRequest) throws {
        let action = request == .menu(["View", "Toggle Sidebar"]) ? "View > Toggle Sidebar" : "the toolbar's toggle"
        try app.act(request, action)
        waitUntil(5) { (try? app.state()).map { ($0.sidebarWidth > 0) == shown } == true }
        let width = try app.state().sidebarWidth
        try expect((width > 0) == shown, "\(action): after 5 s the sidebar is \(width > 0 ? "shown" : "hidden"), "
                   + "not \(shown ? "shown" : "hidden")")
    }
}
