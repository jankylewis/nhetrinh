import Foundation
import NhetrinhCore

/// R19 to R26b: the P3 readback (hubs/product/plan/M2_REAL_SITES_WORK.md), what every site expects of
/// a browser. Every page is the readback's own (`BasicPages`, 127.0.0.1); each step starts from one home tab.
enum BasicSteps {
    static let all: [Step] = [
        Step(id: "R19", name: "alert shows its text in a sheet; OK closes it", run: alertShows),
        Step(id: "R20", name: "confirm: Cancel gives false, OK gives true", run: confirmAnswers),
        Step(id: "R21", name: "prompt: the typed text reaches the page", run: promptTyped),
        Step(id: "R22", name: "a file input opens the open panel; Cancel closes it", run: PanelSteps.fileInput),
        Step(id: "R23", name: "a closed port shows the error page; Retry loads the page", run: LoadSteps.retry),
        Step(id: "R24", name: "Basic sign-in: a wrong password asks again, the right one loads",
             run: LoadSteps.signIn),
        Step(id: "R25", name: "File > Print… opens the print panel; Cancel closes it", run: PanelSteps.print),
        Step(id: "R26", name: "a mailto: link asks first; Cancel keeps it in the app", run: PanelSteps.mailto),
        Step(id: "R26a", name: "camera and microphone are asked per site", run: MediaSteps.cameraAndMicrophone),
        Step(id: "R26b", name: "a video goes fullscreen and back", run: MediaSteps.fullscreen),
    ]

    private static func dialogs(_ app: AppSession) throws {
        _ = try PageSteps.openTest(app, "/dialogs", title: BasicPages.dialogsTitle)
    }

    static func alertShows(_ app: AppSession) throws -> String {
        try dialogs(app)
        try SheetDriving.click(app, "#alert", "alert")
        let sheet = try SheetDriving.sheet(app, text: "nhetrinh alert test")
        try expect(sheet.sheetButtons == ["OK"], "the alert sheet's buttons are \(sheet.sheetButtons)")
        try SheetDriving.press(app, "OK")
        _ = try SheetDriving.gone(app, after: "OK")
        try SheetDriving.title(app, "alert: closed", after: "OK")
        return "alert: a sheet \"\(oneLine(sheet.sheet))\" \(sheet.sheetButtons); OK closed it, the page went on"
    }

    static func confirmAnswers(_ app: AppSession) throws -> String {
        try dialogs(app)
        var seen: [String] = []
        for (button, answer) in [("Cancel", "false"), ("OK", "true")] {
            let shown = try app.state().sheetsShown
            try SheetDriving.click(app, "#confirm", "confirm")
            let sheet = try SheetDriving.sheet(app, text: "nhetrinh confirm test", after: shown)
            try expect(Set(sheet.sheetButtons) == ["OK", "Cancel"],
                       "the confirm sheet's buttons are \(sheet.sheetButtons)")
            try SheetDriving.press(app, button)
            try SheetDriving.title(app, "confirm: \(answer)", after: button)
            seen.append("\(button): \(answer)")
        }
        return "confirm: a sheet [OK, Cancel]; " + seen.joined(separator: ", ")
    }

    static func promptTyped(_ app: AppSession) throws -> String {
        try dialogs(app)
        let typed = "typed by the readback"
        try SheetDriving.click(app, "#prompt", "prompt")
        _ = try SheetDriving.sheet(app, text: "nhetrinh prompt test")
        try app.act(.sheetField(index: 0, text: typed), "type in the prompt's field")
        try SheetDriving.press(app, "OK")
        try SheetDriving.title(app, "prompt: \(typed)", after: "typed \"\(typed)\", OK")
        return "prompt: a sheet with a field; typed \"\(typed)\", OK: the page got it"
    }

    static func oneLine(_ text: String) -> String { text.replacingOccurrences(of: "\n", with: " / ") }
}
