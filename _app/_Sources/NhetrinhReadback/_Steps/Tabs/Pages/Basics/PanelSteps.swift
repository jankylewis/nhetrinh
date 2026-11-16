import AppKit
import Foundation
import NhetrinhCore

/// R22, R25, R26: the open panel, the print panel, a link to another app.
enum PanelSteps {
    /// What R22's line says of the file choice (ruling on NT-TG-006): the open panel is the system's, the
    /// readback cannot pick in it; the choice is the unit test `UploadTests` (`uploadAnswer`).
    static let fileChoiceUnitOnly = "file choice: unit test only"

    /// R22: the open panel is shown for the page's file input, and Cancel gives the page nothing chosen.
    static func fileInput(_ app: AppSession) throws -> String {
        _ = try PageSteps.openTest(app, "/upload", title: BasicPages.uploadTitle)
        try SheetDriving.click(app, "#pick", "the file input's label")
        _ = try SheetDriving.sheet(app, kind: "open")
        try SheetDriving.press(app, "Cancel")
        var state = try SheetDriving.gone(app, after: "Cancel")
        waitUntil(3) {
            state = (try? app.state()) ?? state
            return state.title == BasicPages.uploadCancelTitle
        }
        let cancel = try cancelPart(title: state.title)
        return "the file input: the open panel shown as a sheet; \(cancel); \(fileChoiceUnitOnly)"
    }

    /// The page's title after Cancel: "file: cancel" (WebKit's `cancel` event) or unchanged is nothing
    /// chosen; "file: <name>" means the page got a file: FAIL.
    static func cancelPart(title: String) throws -> String {
        if title == BasicPages.uploadCancelTitle { return "Cancel: the page heard cancel, nothing chosen" }
        try expect(title == BasicPages.uploadTitle || title == "file: none",
                   "after Cancel the page's title is \"\(title)\": the input got a file")
        return "Cancel: nothing chosen (the page's title stays \"\(title)\")"
    }

    /// Only the kind and Cancel are read: the print panel's other buttons name the Mac's printers.
    static func print(_ app: AppSession) throws -> String {
        _ = try PageSteps.openTest(app, "/page/1", title: TestPageContent.title(page: 1))
        try app.act(.menu(["File", "Print…"]), "File > Print…")
        let shown = try SheetDriving.sheet(app, kind: "print")
        try expect(shown.sheetButtons.contains("Cancel"), "the print panel has no Cancel button the app can press")
        try SheetDriving.press(app, "Cancel")
        _ = try SheetDriving.gone(app, after: "Cancel")
        return "File > Print…: the print panel shown as a sheet; Cancel closed it; nothing printed"
    }

    static func mailto(_ app: AppSession) throws -> String {
        let handler = URL(string: BasicPages.mailto).flatMap { NSWorkspace.shared.urlForApplication(toOpen: $0) }
        let handlerID = handler.flatMap { Bundle(url: $0)?.bundleIdentifier }
        let ranBefore = handlerID.map(running) ?? false
        let url = try PageSteps.openTest(app, "/mailto", title: BasicPages.mailtoTitle)
        try SheetDriving.click(app, "#mail", "the mailto: link")
        let sheet = try SheetDriving.sheet(app, text: "mailto:")
        try expect(sheet.sheetButtons.contains("Cancel") || handler == nil,
                   "the ask sheet's buttons: \(sheet.sheetButtons)")
        try SheetDriving.press(app, handler == nil ? "OK" : "Cancel")
        let state = try SheetDriving.gone(app, after: "Cancel")
        Thread.sleep(forTimeInterval: 2)
        try expect(state.handedOff == 0, "after Cancel the app handed \(state.handedOff) link(s) to macOS")
        try expect(state.address == url, "after Cancel the address bar shows \"\(state.address)\", not \(url)")
        let started = !ranBefore && (handlerID.map(running) ?? false)
        try expect(!started, "after Cancel the mail app (\(handlerID ?? "")) runs")
        return "a mailto: link: the sheet \"\(BasicSteps.oneLine(sheet.sheet))\" \(sheet.sheetButtons); "
            + "Cancel: 0 links handed to macOS, the page stays, the mail app not started"
    }

    private static func running(_ bundleID: String) -> Bool {
        !NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).isEmpty
    }
}
