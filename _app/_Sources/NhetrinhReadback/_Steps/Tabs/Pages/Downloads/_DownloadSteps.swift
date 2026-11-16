import AppKit
import Foundation
import NhetrinhCore

/// R31 to R35: the P5 readback (hubs/product/plan/M2_REAL_SITES_WORK.md): downloads to ~/Downloads
/// and links from other apps. Every page is the readback's own; every file it makes is removed at the
/// end (`DownloadFiles.cleanUp`). The default browser is never read or changed.
enum DownloadSteps {
    static let all: [Step] = [
        Step(id: "R31", name: "a 1 MB attachment: a footer row, the file in ~/Downloads at its size", run: attachment),
        Step(id: "R32", name: "the same file again is saved as `name (1)`", run: again),
        Step(id: "R33", name: "a slow 20 MB download: Cancel leaves no file", run: cancelSlow),
        Step(id: "R34", name: "a click on a finished row asks Finder to show the file", run: reveal),
        Step(id: "R35", name: "a link from another app (open -b) opens as a new tab", run: IncomingStep.link),
    ]

    static let bundleId = "io.github.jankylewis.nhetrinh"
    private static let name = DownloadPages.attachmentName

    static func attachment(_ app: AppSession) throws -> String {
        DownloadFiles.cleanUp()
        try LifecycleSteps.freshStart(app)
        _ = try DownloadFiles.download(app, "/download/attachment", as: name)
        let size = try DownloadFiles.size(name)
        try expect(size == DownloadPages.attachmentSize,
                   "~/Downloads/\(name): \(size.map { "\($0) bytes" } ?? "none")")
        return "the footer row \(name) (done); ~/Downloads/\(name): \(DownloadPages.attachmentSize) bytes"
    }

    static func again(_ app: AppSession) throws -> String {
        try LifecycleSteps.freshStart(app)
        if try DownloadFiles.size(name) == nil { _ = try DownloadFiles.download(app, "/download/attachment", as: name) }
        let copy = DownloadPages.copy(name, clash: 1)
        if let file = DownloadFiles.folder?.appendingPathComponent(copy) {
            try? FileManager.default.removeItem(at: file)
        }
        _ = try DownloadFiles.download(app, "/download/attachment", as: copy)
        let first = try DownloadFiles.size(name), second = try DownloadFiles.size(copy)
        try expect(first == DownloadPages.attachmentSize && second == DownloadPages.attachmentSize,
                   "~/Downloads: \(name) \(first ?? -1) bytes, \(copy) \(second ?? -1) bytes")
        return "\(name) kept; the second is \(copy), \(DownloadPages.attachmentSize) bytes"
    }

    static func cancelSlow(_ app: AppSession) throws -> String {
        let slow = DownloadPages.slowName
        try LifecycleSteps.freshStart(app)
        try app.act(.navigate(try LifecycleSteps.pages().url("/download/slow")), "address bar: /download/slow, Return")
        let running = try ToolSteps.until(app, within: 20, { $0.downloads.first == slow && saving($0) },
                                          else: { "the slow download shows \($0.downloads) \($0.downloadStates)" })
        try app.act(.download(row: 0, item: "Cancel"), "download row 1: Cancel")
        _ = try ToolSteps.until(app, { $0.downloadStates.first == "cancelled" },
                                else: { "Cancel pressed: the row shows \($0.downloadStates)" })
        Thread.sleep(forTimeInterval: 2)  // the app removes a cancelled file at once and again 0.5 s later
        let left = try (0...5).map { DownloadPages.copy(slow, clash: $0) }.filter { try DownloadFiles.size($0) != nil }
        try expect(left.isEmpty, "cancelled, 2 s later ~/Downloads still has \(left)")
        return "\(slow) at \(running.downloadStates.first ?? ""), Cancel: the row says cancelled, no file is left"
    }

    /// The top row is saving: a percent above 0 (a row that stays at "…" waits for macOS: `check`).
    private static func saving(_ state: ProbeState) -> Bool {
        let top = state.downloadStates.first ?? ""
        return top.hasSuffix(" %") && top != "0 %" && top != "100 %"
    }

    static func reveal(_ app: AppSession) throws -> String {
        try LifecycleSteps.freshStart(app)
        let copy = (0...5).map { DownloadPages.copy(name, clash: $0) }.first { (try? DownloadFiles.size($0)) == nil }
        guard let copy else { throw StepError.cannotDrive("~/Downloads already has \(name) and 5 copies") }
        _ = try DownloadFiles.download(app, "/download/attachment", as: copy)
        try app.act(.download(row: 0, item: "Show in Finder"), "download row 1: click")
        let state = try ToolSteps.until(app, { $0.revealed.contains(copy) },
                                        else: { "row clicked: Finder was asked for \($0.revealed)" })
        return "row \(copy) clicked: Finder was asked to show it (revealed \(state.revealed))"
    }
}
