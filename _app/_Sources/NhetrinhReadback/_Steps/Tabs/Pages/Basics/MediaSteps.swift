import Foundation
import NhetrinhCore

/// R26a and R26b: camera and microphone per site, fullscreen video. macOS asks for the camera and the
/// microphone itself too; that prompt is the system's: when it waits, the step is NOT READ BACK. A page
/// WebKit counts as hidden (the readback starts the app without the focus, D18, so other windows may
/// cover it) gets neither: that is NOT READ BACK too, with WebKit's own words.
enum MediaSteps {
    static func cameraAndMicrophone(_ app: AppSession) throws -> String {
        _ = try PageSteps.openTest(app, "/media", title: BasicPages.mediaTitle)
        let deny = try ask(app, "#camera", "camera", answer: "Don't Allow", host: "127.0.0.1")
        try expect(deny.title == "media: NotAllowedError", "Don't Allow: the page's title is \"\(deny.title)\"")
        try SheetDriving.click(app, "#camera", "camera, again")
        let kept = try SheetDriving.title(app, "media: NotAllowedError", after: "camera, again")
        try expect(kept.sheetsShown == deny.sheetsShown, "the same site was asked again for the camera")
        let local = try LifecycleSteps.pages().url("/media").replacingOccurrences(of: "127.0.0.1", with: "localhost")
        try app.act(.navigate(local), "address bar: the media page on localhost, Return")
        try SheetDriving.title(app, BasicPages.mediaTitle, after: "typed \(local)", timeout: 15)
        let allow = try ask(app, "#mic", "microphone", answer: "Allow", host: "localhost")
        let done = "the camera sheet named 127.0.0.1, Don't Allow: NotAllowedError, not asked again; "
            + "another site (localhost) asked for the microphone, Allow"
        switch allow.title {
        case "media: granted": return done + ": granted"
        case "media: asking":
            throw StepError.cannotDrive(done + "; then the macOS prompt for the microphone waits: not read back")
        default: throw StepError.cannotDrive(done + "; macOS answered \"\(allow.title)\": not read back")
        }
    }

    /// Click `selector`, wait for the site's sheet, press `answer`; the state 10 s later at most.
    private static func ask(_ app: AppSession, _ selector: String, _ kind: String, answer: String,
                            host: String) throws -> ProbeState {
        let shown = try app.state().sheetsShown
        try SheetDriving.click(app, selector, kind)
        let question = SitePermissions.question(host: host, kind: kind == "camera" ? .camera : .microphone)
        let sheet: ProbeState
        do { sheet = try SheetDriving.sheet(app, text: question, after: shown) } catch StepError.fail(let why) {
            let hidden = (try? app.state().title) == "media: asking (hidden)"
            throw StepError.cannotDrive(hidden
                ? "the \(kind) was asked in a page WebKit counts as hidden (no focus, D18): no site sheet in 10 s, "
                    + "the macOS prompt not reached: not read back"
                : "no site sheet for the \(kind) (\(why)): the macOS prompt may come first: not read back")
        }
        try expect(Set(sheet.sheetButtons) == ["Allow", "Don't Allow"],
                   "the \(kind) sheet's buttons: \(sheet.sheetButtons)")
        try SheetDriving.press(app, answer)
        var state = try app.state()
        waitUntil(10) {
            state = (try? app.state()) ?? state
            return state.title != "media: asking"
        }
        return state
    }

    static func fullscreen(_ app: AppSession) throws -> String {
        _ = try PageSteps.openTest(app, "/fullscreen", title: BasicPages.fullscreenTitle)
        try SheetDriving.click(app, "#full", "fullscreen")
        var title = ""
        waitUntil(10) {
            title = (try? app.state().title) ?? title
            return title.hasPrefix("fullscreen: ")
        }
        if title.contains("hidden document") {
            throw StepError.cannotDrive("WebKit refused: \"\(title)\"; the readback starts the app without the "
                + "focus (D18), so the page counts as hidden: not read back")
        }
        try SheetDriving.title(app, "fullscreen: on", after: "fullscreen pressed")
        try SheetDriving.title(app, "fullscreen: off", after: "the page left fullscreen")
        return "a video's fullscreen button: the page went fullscreen, then left it by itself"
    }
}
