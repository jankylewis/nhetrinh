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
    let hasOwnID: Bool
    let verdict: Verdict
    var testDescription: String {
        "an element missing from \(children) child(ren), \(hasOwnID ? "other" : "no") nhetrinh.* identifier"
    }
}

@Test("an element missing is FAIL only when other own identifiers were read", arguments: [
    MissingCase(children: 0, hasOwnID: false, verdict: .notReadBack),
    MissingCase(children: 4, hasOwnID: false, verdict: .notReadBack),
    MissingCase(children: 1, hasOwnID: true, verdict: .fail),
    MissingCase(children: 7, hasOwnID: true, verdict: .fail),
])
func missingElement(_ missing: MissingCase) {
    let read = WindowRead(title: "Example Domain", children: missing.children,
                          firstRoles: Array(["AXButton", "", "AXGroup"].prefix(missing.children)),
                          error: -25204, hasOwnID: missing.hasOwnID)
    let (seen, detail) = verdict(EmptyReads.missing("nhetrinh.sidebar", in: read, grantee: grantee))
    #expect(seen == missing.verdict)
    #expect(detail.contains("nhetrinh.sidebar"))
    #expect(detail.hasPrefix(regrant) == (missing.children == 0))
    // NOT READ BACK says what was read; a FAIL keeps its short reason.
    #expect(detail.contains("window \"Example Domain\", \(missing.children) children") == !missing.hasOwnID)
    #expect(detail.contains("read error -25204") == !missing.hasOwnID)
}

@Test("a tree read without own identifiers lists the window's first roles") func notReadTreeSaysWhatWasRead() {
    let read = WindowRead(title: "", children: 4, firstRoles: ["AXButton", "", "AXGroup"], error: 0, hasOwnID: false)
    let (seen, detail) = verdict(EmptyReads.missing("nhetrinh.address", in: read, grantee: grantee))
    #expect(seen == .notReadBack)
    #expect(detail == "no element `nhetrinh.address`: none of the app's identifiers (nhetrinh.*) is in the window, "
        + "its tree was not read (window \"\", 4 children, first roles [AXButton, (empty), AXGroup], read error 0)")
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

struct WindowCase: CustomTestStringConvertible {
    let roles: [String]
    let pick: Int?
    let notReadBack: Bool
    var testDescription: String { "AXWindows read as \(roles)" }
}

/// NT-GAT-008, 20:07: the first element `AXWindows` gave held [AXApplication, AXMenuBar]. The old
/// `window()` took `windows.first` whatever its role; these cases fail against that rule.
@Test("only an element with the role AXWindow is the app's window", arguments: [
    WindowCase(roles: [], pick: nil, notReadBack: false),
    WindowCase(roles: ["AXWindow"], pick: 0, notReadBack: false),
    WindowCase(roles: ["AXApplication", "AXWindow"], pick: 1, notReadBack: false),
    WindowCase(roles: ["AXApplication"], pick: nil, notReadBack: true),
    WindowCase(roles: [""], pick: nil, notReadBack: true),
])
func windowIsPickedByRole(_ read: WindowCase) {
    do {
        #expect(try WindowRole.pick(read.roles) == read.pick)
        #expect(!read.notReadBack)
    } catch StepError.cannotDrive(let why) {
        #expect(read.notReadBack)
        #expect(why.contains("none has the role AXWindow"))
        #expect(why.contains(read.roles[0].isEmpty ? "[(empty)]" : "[\(read.roles[0])]"))
    } catch {
        Issue.record("unexpected error \(error)")
    }
}
