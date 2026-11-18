import Foundation
import Testing
@testable import NhetrinhCore

/// P9-REMEMBER (D28): the marker tells a clean quit from a crash. In a temporary folder only.
struct CleanQuitTests {
    @Test func aFirstLaunchIsNoCrash() throws {
        let marker = CleanQuitMarker(folder: try tempFolder())
        #expect(try marker.launch() == false)
        #expect(FileManager.default.fileExists(atPath: marker.file.path))
    }

    /// `clean`: the last run cleared its marker. Without it, the next launch reads a crash.
    @Test(arguments: [(clean: true, crashed: false), (clean: false, crashed: true)])
    func theNextLaunchReadsHowTheLastEnded(clean: Bool, crashed: Bool) throws {
        let marker = CleanQuitMarker(folder: try tempFolder())
        _ = try marker.launch()
        if clean { try marker.clear() }
        #expect(try marker.launch() == crashed)
    }

    @Test func aMissingFolderIsMade() throws {
        let folder = try tempFolder().appendingPathComponent("profile")
        #expect(try CleanQuitMarker(folder: folder).launch() == false)
        #expect(FileManager.default.fileExists(atPath: folder.appendingPathComponent(CleanQuitMarker.fileName).path))
    }

    @Test func clearingNoMarkerIsNoError() throws {
        let marker = CleanQuitMarker(folder: try tempFolder())
        try marker.clear()
        #expect(!FileManager.default.fileExists(atPath: marker.file.path))
    }

    /// Defect 5 (REVIEW_P9_REMEMBER.md): a quit before the restore ends is a clean quit and leaves the item
    /// as it was, so the next launch restores it. Not a crash, nothing deleted, nothing half-written.
    @Test(arguments: [0, 1])
    func aQuitWhileRestoringIsCleanAndKeepsTheItem(setMeanwhile: Int) throws {
        let rig = try Rig()
        let item = try SignIns.encode(fakeCookies(session: 2, dated: 0))
        rig.secrets.items[rig.service] = item
        let pending = PendingJar()
        pending.cookies = (0..<setMeanwhile).compactMap { fakeCookie("late\($0)", session: true) }
        let first = rig.keeper(jar: pending)
        #expect(rig.count { first.launch(remember: true, done: $0) } == -1)  // still restoring
        #expect(rig.count { first.quit(remember: true, done: $0) } == 0)
        first.cleanQuit()
        #expect(rig.item == item)
        #expect(rig.count { rig.keeper().launch(remember: true, done: $0) } == 2)
        #expect(rig.item == nil)
    }

    /// Every launch ends with a delete, even with no item or an unreadable one: in the app a delete this
    /// signature may not make empties the item instead (`KeychainSecrets.delete`, NT-BLD-006).
    @Test(arguments: ["missing", "unreadable"])
    func everyLaunchDeletes(problem: String) throws {
        let rig = try Rig()
        if problem == "unreadable" { rig.secrets.failure = .status(-25293) }
        _ = rig.count { rig.keeper().launch(remember: true, done: $0) }
        #expect(rig.secrets.deletes >= 1)
    }

    /// An emptied item (one this build could not delete, NT-BLD-006) is no sign-in kept, not a corrupt one.
    @Test func anEmptiedItemIsNoneKept() throws {
        let rig = try Rig()
        rig.secrets.items[rig.service] = Data()
        #expect(rig.count { rig.keeper().launch(remember: true, done: $0) } == 0)
        #expect(rig.lines.contains { $0.contains("none kept") } && !rig.lines.contains { $0.contains("corrupt") })
    }
}
