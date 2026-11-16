import AppKit
import Testing
@testable import NhetrinhReadback

/// NT-TG-003, readback 19:51: the grant record was kept and `AXIsProcessTrusted` was true, yet every
/// read came back empty; R2 read 0 Dock items. A read that is refused says nothing about the app:
/// R2 is NOT READ BACK and asks for a new grant. (R1, R3-R7 no longer read Accessibility: D23.)
private let grantee = "nhetrinh-readback.app"
private let regrant = "Accessibility reads are empty: re-grant nhetrinh-readback.app"

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
