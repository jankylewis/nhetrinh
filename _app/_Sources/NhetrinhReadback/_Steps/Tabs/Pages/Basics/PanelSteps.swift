import AppKit
import Foundation
import NhetrinhCore

/// R22, R25, R26: the open panel, the print panel, a link to another app.
enum PanelSteps {
    /// The open panel is the system's: the readback sees it shown and cancels it. Picking a file in it
    /// is not driven (the panel runs outside the app), so the detail says "not read back" for that part.
    static func fileInput(_ app: AppSession) throws -> String {
        _ = try PageSteps.openTest(app, "/upload", title: BasicPages.uploadTitle)
        try SheetDriving.click(app, "#pick", "the file input's label")
        _ = try SheetDriving.sheet(app, kind: "open")
        try SheetDriving.press(app, "Cancel")
        let state = try SheetDriving.gone(app, after: "Cancel")
        return "the file input: the open panel shown as a sheet; Cancel closed it (title \"\(state.title)\"); "
            + "picking a file in the panel: not read back"
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
