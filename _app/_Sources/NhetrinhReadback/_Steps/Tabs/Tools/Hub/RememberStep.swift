import Foundation
import NhetrinhCore

/// R51 (P9-REMEMBER, D28): Remember sign-ins after quit, as a user meets it. A page sets a session cookie (no
/// expiry: WebKit never writes one to disk); with the switch on (the default) it is there after Quit and a
/// launch; with the switch off it is gone. The switch is put back on. Only the readback profile's own
/// Keychain item is used (`SignIns.service(profile: "readback")`); the step reports counts, never a value.
/// Not read back here: the crash marker (a kill leaves no item to skip; unit tested in `SignInKeeperTests`).
enum RememberStep {
    static let title = "Remember sign-ins after quit"
    static let step = Step(id: "R51", name: "a session sign-in comes back after Quit with the switch on, "
        + "not with it off", run: run)

    static func run(_ app: AppSession) throws -> String {
        try ToolSteps.fresh(app)  // no prefs: the switch is on by default
        let on = try roundTrip(app)
        try expect(on == ToolPages.sessionTitle(kept: true), failure(switchOn: true, seen: on) ?? "")
        try HubSteps.openHub(app)
        try app.act(.setting(name: title, value: "off"), "Settings Hub: \(title) off")
        let off = try roundTrip(app)
        try HubSteps.openHub(app)
        try app.act(.setting(name: title, value: "on"), "Settings Hub: \(title) on (put back)")
        if let failure = failure(switchOn: false, seen: off) { throw StepError.fail(failure) }
        return passLine
    }

    /// What a pass says: only what the step read on the page (no count: the step reads none).
    static let passLine = "switch on: a page set a session cookie; after Quit and a launch the page read it; "
        + "switch off: after Quit and a launch the page read none; the switch put back on"

    /// The session cookie set, Quit, a launch, then what the read page shows.
    private static func roundTrip(_ app: AppSession) throws -> String {
        try ToolSteps.open(app, "/cookie/session", title: ToolPages.sessionSetTitle)
        try app.act(.menu(["nhetrinh", "Quit nhetrinh"]), "nhetrinh > Quit nhetrinh")
        try expect(app.waitForEnd(10), "nhetrinh > Quit nhetrinh: the app still runs after 10 s")
        try app.launch(probe: true)
        let url = try LifecycleSteps.pages().url("/cookie/session/read")
        try app.act(.navigate(url), "after the launch: /cookie/session/read, Return")
        var seen = ""
        waitUntil(15) {
            seen = (try? app.state().title) ?? seen
            return seen.hasPrefix("session: ") && seen != ToolPages.sessionSetTitle
        }
        return seen
    }

    /// Why R51 fails for what the read page showed, or nil: on, the cookie is back; off, it is gone.
    static func failure(switchOn: Bool, seen: String) -> String? {
        let wanted = ToolPages.sessionTitle(kept: switchOn)
        guard seen != wanted else { return nil }
        return "switch \(switchOn ? "on" : "off"): after Quit and a launch the page read \"\(seen)\", "
            + "not \"\(wanted)\""
    }
}
