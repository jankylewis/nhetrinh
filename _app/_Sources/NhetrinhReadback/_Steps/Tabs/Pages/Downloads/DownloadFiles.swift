import Foundation
import NhetrinhCore

/// The readback's own files in ~/Downloads (P5) and the wait for a download row. Only names that start
/// with `nhetrinh-readback-` are ever removed; any other file there is never touched.
enum DownloadFiles {
    static let folder = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first
    /// The reason when macOS has not let nhetrinh into ~/Downloads (NOT READ BACK: the headmate grants it).
    static let noAccess = "macOS has not let nhetrinh into the Downloads folder: the headmate allows it "
        + "(the macOS prompt, or System Settings > Privacy & Security > Files and Folders)"

    /// Every name a run can make: the two pages' names and their first 5 copies.
    static var ours: [String] {
        [DownloadPages.attachmentName, DownloadPages.slowName].flatMap { name in
            (0...5).map { DownloadPages.copy(name, clash: $0) }
        }
    }

    /// Remove the readback's own files; the names that were there.
    @discardableResult
    static func cleanUp() -> [String] {
        guard let folder else { return [] }
        return ours.filter { (try? FileManager.default.removeItem(at: folder.appendingPathComponent($0))) != nil }
    }

    /// The file's size in ~/Downloads; nil when there is none. A folder the readback cannot read: NOT READ BACK.
    static func size(_ name: String) throws -> Int? {
        guard let folder else { throw StepError.cannotDrive("this user has no Downloads folder") }
        let path = folder.appendingPathComponent(name).path
        do {
            return (try FileManager.default.attributesOfItem(atPath: path)[.size] as? NSNumber)?.intValue
        } catch let error as NSError where error.code == NSFileReadNoSuchFileError {
            return nil
        } catch {
            throw StepError.cannotDrive("the readback cannot read ~/Downloads: \(error.localizedDescription)")
        }
    }

    /// Open `path` (a download) in the selected tab; wait until the top footer row is `name` and done.
    static func download(_ app: AppSession, _ path: String, as name: String, within timeout: TimeInterval = 30)
        throws -> ProbeState {
        let url = try LifecycleSteps.pages().url(path)
        try app.act(.navigate(url), "address bar: \(path), Return")
        var state = try app.state()
        var answers = true
        waitUntil(timeout) {
            let read = try? app.state()
            answers = read != nil
            state = read ?? state
            return state.downloads.first == name && ["done", "cancelled"].contains(state.downloadStates.first)
                || state.downloadStates.first?.hasPrefix("failed") == true
        }
        // Before the fix, macOS's question froze the app inside WebKit: its last answer was the state before.
        guard answers else { throw StepError.cannotDrive(noAccess + "; the app stopped answering the probe") }
        try check(state, name: name, after: path)
        return state
    }

    /// FAIL, or NOT READ BACK when macOS kept nhetrinh out of ~/Downloads, unless the top row is `name`, done.
    static func check(_ state: ProbeState, name: String, after path: String) throws {
        let shown = zip(state.downloads, state.downloadStates).map { "\($0) (\($1))" }
        guard let top = state.downloadStates.first else {
            throw StepError.fail("\(path): no download row (downloads \(state.downloads), rows \(state.rows), "
                + "address \(state.address))")
        }
        if top.contains("no access to the Downloads folder") { throw StepError.cannotDrive(noAccess) }
        if top == "…" || top == "0 %" {
            throw StepError.cannotDrive(noAccess + "; the row stayed \"\(top)\": " + shown.joined(separator: ", "))
        }
        try expect(state.downloads.first == name && top == "done", "\(path): the footer shows \(shown)")
    }
}
