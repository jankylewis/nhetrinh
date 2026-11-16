import AppKit
import Foundation
import NhetrinhCore

/// R35: a link another app hands over, as `open` hands it: `open -g -b <bundle id> <url>`. `-g` keeps
/// nhetrinh in the background (D18). Only the readback's own instance may run, or the link could go to
/// the headmate's. The default browser is never read or changed.
enum IncomingStep {
    static func link(_ app: AppSession) throws -> String {
        try LifecycleSteps.freshStart(app)
        let others = NSRunningApplication.runningApplications(withBundleIdentifier: DownloadSteps.bundleId)
            .map(\.processIdentifier).filter { $0 != app.pid }
        guard others.isEmpty else {
            throw StepError.cannotDrive("another nhetrinh runs (pid \(others)): the link could reach it, not the "
                + "readback's own instance")
        }
        let before = try app.state()
        let url = try LifecycleSteps.pages().url("/page/35")
        let status = try open(url)
        guard status == 0 else {
            throw StepError.cannotDrive("open -g -b \(DownloadSteps.bundleId) exited \(status)")
        }
        let count = before.rows.count + 1
        let after = try ToolSteps.until(app, within: 15, { $0.rows.count == count && $0.address == url },
                                        else: { "rows \(before.rows) -> \($0.rows); address \"\($0.address)\"" })
        return "open -g -b \(DownloadSteps.bundleId) \(url): rows \(before.rows.count) -> \(after.rows.count), "
            + "the new tab shows \(url)"
    }

    private static func open(_ url: String) throws -> Int32 {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = ["-g", "-b", DownloadSteps.bundleId, url]
        do { try process.run() } catch { throw StepError.cannotDrive("open could not start: \(error)") }
        process.waitUntilExit()
        return process.terminationStatus
    }
}
