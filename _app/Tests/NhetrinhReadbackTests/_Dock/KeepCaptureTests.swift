import AppKit
import Testing
@testable import NhetrinhReadback

/// `--keep-capture <dir>` keeps R2's capture to find out why R2 sees a tile the headmate does not
/// (19:28 run). A capture is a picture of the screen and the repository is public, so a folder
/// inside the nhetrinh repository, or inside any git repository or worktree, is a usage error.
/// The fake disk: the nhetrinh repository at /repo, a worktree at /wt/a (`.git` file), /out free.
private let disk: Set<String> = ["/repo/hubs/failures/evidence", "/repo/_app/Package.swift", "/wt/a/.git"]
private let onDisk: (String) -> Bool = { disk.contains($0) }

@Test("a folder inside a repository is refused", arguments: [
    "/repo", "/repo/", "/repo/hubs/failures/evidence/readback", "/repo/_app/build/r2", "/out/../repo/x",
    "/wt/a", "/wt/a/hubs/r2", "/wt/b/../a/r2", "out/r2",
])
func keepCaptureRefusesARepository(folder: String) {
    #expect(throws: UsageError.self) {
        try Options(["readback", "--keep-capture", folder], known: known, exists: onDisk)
    }
}

@Test("a folder outside any repository is kept", arguments: ["/out", "/out/r2", "/wt/b", "/repository"])
func keepCaptureTakesAFolderOutside(folder: String) throws {
    let options = try Options(["readback", "--keep-capture", folder], known: known, exists: onDisk)
    #expect(options.keepCapture == URL(fileURLWithPath: folder))
}

@Test("without the flag nothing is kept") func keepCaptureIsOffByDefault() throws {
    #expect(try Options(["readback"], known: known, exists: onDisk).keepCapture == nil)
    #expect(AppSession(appURL: AppSession.installed).keepCapture == nil)
}

@Test("the flag needs a value and is given once", arguments: [
    ["readback", "--keep-capture"],
    ["readback", "--keep-capture", "--steps", "R2"],
    ["readback", "--keep-capture", "/out", "--keep-capture", "/out2"],
])
func keepCaptureMisuseIsAUsageError(arguments: [String]) {
    #expect(throws: UsageError.self) { try Options(arguments, known: known, exists: onDisk) }
}

/// The text file beside the PNG: what R2 judged and where, in points; no path.
@Test func keptNoteHoldsTheNumbers() {
    let item = DockItem(frame: CGRect(x: 100, y: 1000, width: 64, height: 64),
                        dock: CGRect(x: 0, y: 990, width: 800, height: 80))
    let match = IconMatch(agreement: 0.7712, scale: 0.84, background: [30.2, 31, 35.6])
    let note = DockIcon.note(match, item: item)
    #expect(note.contains("agreement: 0.771\n"))
    #expect(note.contains("scale: 0.84\n"))
    #expect(note.contains("background (sRGB 0-255): 30 31 36\n"))
    #expect(note.contains("item: x 100.0 y 1000.0 w 64.0 h 64.0\n"))
    #expect(note.contains("dock: x 0.0 y 990.0 w 800.0 h 80.0\n"))
    #expect(note.contains("capture: x 100.0 y 1000.0 w 64.0 h 64.0\n"))
    #expect(!note.contains("/"))
}

/// NT-GAT-015: a FAIL line says what was measured: the item's frame (points) and the capture (pixels).
@Test func failLineNamesTheItemAndTheCapture() {
    let image = bitmap(wide: 60, high: 44) { _ in }
    let line = DockIcon.geometry(CGRect(x: 13.6, y: 467, width: 34, height: 22), capture: image)
    #expect(line == "item x 13.6 y 467.0 w 34.0 h 22.0 pt, capture 60 x 44 px")
}
