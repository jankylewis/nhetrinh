import AppKit
import Testing
@testable import NhetrinhReadback

/// NT-TG-003, readback 19:51: the grant record was kept and `AXIsProcessTrusted` was true, yet every
/// read came back empty. R1, R3-R7 said FAIL "no element", R2 read 0 Dock items. A read that is
/// refused says nothing about the app: such a step is NOT READ BACK and asks for a new grant.
private let grantee = "nhetrinh-readback.app"
private let regrant = "Accessibility reads are empty: re-grant nhetrinh-readback.app"

private func verdict(_ error: StepError) -> (Verdict, String) {
    let step = Step(id: "R0", name: "throws", run: { _ in throw error })
    let result = Runner.run([step], in: AppSession(appURL: AppSession.installed))[0]
    return (result.verdict, result.detail)
}

struct MissingCase: CustomTestStringConvertible {
    let children: Int
    let verdict: Verdict
    var testDescription: String { "an element missing from a window with \(children) child(ren)" }
}

@Test("an element missing from an empty tree is not read back", arguments: [
    MissingCase(children: 0, verdict: .notReadBack),
    MissingCase(children: 1, verdict: .fail),
    MissingCase(children: 7, verdict: .fail),
])
func missingElement(_ missing: MissingCase) {
    let error = EmptyReads.missing("nhetrinh.sidebar", children: missing.children, error: -25204, grantee: grantee)
    let (seen, detail) = verdict(error)
    #expect(seen == missing.verdict)
    #expect(detail.hasPrefix(regrant) == (missing.verdict == .notReadBack))
    #expect(detail.contains("nhetrinh.sidebar"))
}

@Test("the reason names the read error and never a path") func emptyReadReason() {
    let detail = EmptyReads.reason("the window has 0 children", error: -25204, grantee: grantee)
    #expect(detail == regrant + " (the window has 0 children, read error -25204)")
    #expect(!detail.contains("/"))
}

@Test("0 Dock items read is not read back") func noDockItemRead() {
    let app = URL(fileURLWithPath: "/Applications/nhetrinh.app")
    #expect {
        try DockIcon.launchedItem([], app: app, grantee: grantee)
    } throws: { error in
        guard case StepError.cannotDrive(let why) = error else { return false }
        return why.hasPrefix(regrant)
    }
}

@Test("Dock items read, none of the app: not read back, no re-grant asked") func dockItemsButNoneOurs() {
    let app = URL(fileURLWithPath: "/Applications/nhetrinh.app")
    let other = DockItem(frame: CGRect(x: 0, y: 0, width: 64, height: 64), dock: .zero, isRunning: true,
                         url: URL(fileURLWithPath: "/System/Applications/Finder.app"))
    #expect {
        try DockIcon.launchedItem([other], app: app, grantee: grantee)
    } throws: { error in
        guard case StepError.cannotDrive(let why) = error else { return false }
        return why.hasPrefix("no running Dock item") && !why.contains("re-grant")
    }
}
