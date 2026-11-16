import CoreGraphics
import Foundation
import NhetrinhCore

/// D25 (amends D18): WebKit refuses fullscreen, camera and microphone in a page it counts as hidden,
/// and the readback starts nhetrinh without the focus, so other windows may cover it (NT-TG-005).
/// Only R26a and R26b may bring nhetrinh to the front, only with `--allow-focus`, and their report
/// line says they took the focus. Without the flag a hidden page stays NOT READ BACK.
enum Focus {
    static let steps: Set<String> = ["R26a", "R26b"]

    static func took(_ detail: String) -> String { "took the focus (--allow-focus, D25): " + detail }

    static func needed(_ why: String) -> String {
        "\(why); the readback starts nhetrinh without the focus (D18): run with --allow-focus "
            + "to let this step take it (D25): not read back"
    }

    /// Bring nhetrinh to the front when the run allows it; whether it did.
    static func take(_ app: AppSession) throws -> Bool {
        guard app.allowFocus else { return false }
        try app.act(.front, "bring nhetrinh to the front (--allow-focus)")
        Thread.sleep(forTimeInterval: 1)  // WebKit hears that the page is shown
        return true
    }

    /// The reason a refusal in a hidden page gives: with the focus taken, still hidden; else the flag.
    static func hidden(_ what: String, front: Bool) -> StepError {
        let screen = screenNote(locked: screenLocked(), asleep: CGDisplayIsAsleep(CGMainDisplayID()) != 0)
        let why = what + (screen.map { "; \($0)" } ?? "")
        return .cannotDrive(front ? "nhetrinh was brought to the front, yet \(why): not read back" : needed(why))
    }

    /// Why every window is hidden whatever the app does; nil when the screen is on and unlocked.
    static func screenNote(locked: Bool, asleep: Bool) -> String? {
        let states = [locked ? "the screen is locked" : nil, asleep ? "the display is asleep" : nil].compactMap { $0 }
        guard !states.isEmpty else { return nil }
        return states.joined(separator: " and ") + ": macOS hides every window (read back with the screen on)"
    }

    private static func screenLocked() -> Bool {
        let session = CGSessionCopyCurrentDictionary() as? [String: Any]
        return (session?["CGSSessionScreenIsLocked"] as? Bool) ?? false
    }

    /// The line of a step that ran: marked when it took the focus, with whether macOS made nhetrinh active.
    static func line(_ detail: String, front: Bool, active: Bool) -> String {
        front ? took(detail + "; nhetrinh was the active app: \(active ? "yes" : "no")") : detail
    }
}

/// R26a and R26b. R26a never answers Allow: the macOS camera prompt is never asked for, and no
/// system dialog is left on the shared screen (D25).
enum MediaSteps {
    static func cameraAndMicrophone(_ app: AppSession) throws -> String {
        _ = try PageSteps.openTest(app, "/media", title: BasicPages.mediaTitle)
        let front = try Focus.take(app)
        let shown = try app.state().sheetsShown
        try SheetDriving.click(app, "#camera", "camera")
        let question = SitePermissions.question(host: "127.0.0.1", kind: .camera)
        let sheet: ProbeState
        do {
            sheet = try SheetDriving.sheet(app, text: question, after: shown, timeout: 15)
        } catch StepError.fail(let why) {
            guard (try? app.state().title) == "media: asking (hidden)" else { throw StepError.fail(why) }
            throw Focus.hidden("the camera was asked in a page WebKit counts as hidden: no site sheet in 15 s",
                               front: front)
        }
        try expect(Set(sheet.sheetButtons) == ["Allow", "Don't Allow"],
                   "the camera sheet's buttons: \(sheet.sheetButtons)")
        try SheetDriving.press(app, "Don't Allow")
        try SheetDriving.title(app, "media: NotAllowedError", after: "Don't Allow")
        let denied = try SheetDriving.gone(app, after: "Don't Allow")
        try SheetDriving.click(app, "#camera", "camera, again")
        let kept = try SheetDriving.title(app, "media: NotAllowedError", after: "camera, again")
        try expect(kept.sheetsShown == denied.sheetsShown, "the same site was asked again for the camera")
        let detail = "the site sheet \"\(BasicSteps.oneLine(sheet.sheet))\" \(sheet.sheetButtons); Don't Allow: "
            + "NotAllowedError, the macOS prompt never asked for; asked again: no sheet, the answer kept"
        return Focus.line(detail, front: front, active: sheet.active)
    }

    static func fullscreen(_ app: AppSession) throws -> String {
        _ = try PageSteps.openTest(app, "/fullscreen", title: BasicPages.fullscreenTitle)
        let front = try Focus.take(app)
        try SheetDriving.click(app, "#full", "fullscreen")
        var state = try app.state()
        waitUntil(10) {
            state = (try? app.state()) ?? state
            return state.title.hasPrefix("fullscreen: ")
        }
        if state.title.contains("hidden document") {
            throw Focus.hidden("WebKit refused: \"\(state.title)\"", front: front)
        }
        let on = waitUntil(10) {
            state = (try? app.state()) ?? state
            return state.fullscreen && state.title == "fullscreen: on"
        }
        try expect(on, "fullscreen pressed: the window's fullscreen is \(state.fullscreen), "
            + "the title \"\(state.title)\"")
        let active = state.active
        try SheetDriving.click(app, "#leave", "leave fullscreen")
        let back = waitUntil(10) {
            state = (try? app.state()) ?? state
            return !state.fullscreen && state.title == "fullscreen: off" && state.windowShown
        }
        try expect(back, "leave pressed: the window's fullscreen is \(state.fullscreen), the title \"\(state.title)\"")
        let detail = "a video's box, fullscreen pressed: the window went fullscreen; "
            + "leave pressed: the window is back"
        return Focus.line(detail, front: front, active: active)
    }
}
