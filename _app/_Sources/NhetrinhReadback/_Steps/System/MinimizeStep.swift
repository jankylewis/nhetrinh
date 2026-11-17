import Foundation

/// R46 (P8-MIN-1): Window > Minimize (⌘M) puts the window in the Dock, and a click on its Dock item brings
/// it back. Through the probe (D23): the menu item's own action is sent to the window; no focus, no keys.
enum MinimizeStep {
    static let step = Step(id: "R46", name: "Window > Minimize (⌘M) minimizes the window; it comes back", run: run)

    static func run(_ app: AppSession) throws -> String {
        let shortcut = try app.state().shortcuts["Window > Minimize"] ?? "none"
        try expect(shortcut == "⌘M", "Window > Minimize has the shortcut \"\(shortcut)\", not ⌘M")
        try app.act(.window("Minimize"), "Window > Minimize")
        waitUntil(5) { (try? app.state())?.minimized == true }
        let down = try app.state()  // an unreachable probe is NOT READ BACK, never a FAIL
        try expect(down.minimized, "Window > Minimize: after 5 s the window is not minimized")
        try app.act(.window("Restore"), "the window's Dock item")
        waitUntil(5) { (try? app.state()).map { !$0.minimized && $0.windowShown } == true }
        let up = try app.state()
        try expect(!up.minimized && up.windowShown,
                   "restored: after 5 s minimized is \(up.minimized), the window shown is \(up.windowShown)")
        return "Window > Minimize (⌘M): the window minimized; restored from its Dock item: shown, not minimized"
    }
}
