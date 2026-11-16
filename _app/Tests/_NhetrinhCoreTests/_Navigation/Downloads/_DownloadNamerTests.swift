import Foundation
import Testing
@testable import NhetrinhCore

// P5 (hubs/product/plan/M2_REAL_SITES_WORK.md), red first: `DownloadNamer` was a stub that gave the
// site's name back unchanged, so every clash, cut and clean case here failed.

/// The name given when `taken` already holds these names in ~/Downloads.
private func free(_ suggested: String, taken: Set<String>) -> String? {
    DownloadNamer.freeName(suggested, isTaken: { taken.contains($0) })
}

/// Free name, 1 clash, 2 clashes, no extension, dot file, two extensions: the number goes before the
/// last extension; a dot file has none.
@Test(arguments: [
    ("a.pdf", [], "a.pdf"), ("a.pdf", ["a.pdf"], "a (1).pdf"), ("a.pdf", ["a.pdf", "a (1).pdf"], "a (2).pdf"),
    ("a.pdf", ["a (1).pdf"], "a.pdf"), ("README", ["README"], "README (1)"),
    ("README", ["README", "README (1)"], "README (2)"), (".env", [], ".env"), (".env", [".env"], ".env (1)"),
    ("a.tar.gz", ["a.tar.gz"], "a.tar (1).gz"), ("a.", ["a."], "a. (1)"),
] as [(String, Set<String>, String)])
func takesTheFirstFreeName(suggested: String, taken: Set<String>, expected: String) {
    let name = free(suggested, taken: taken)
    #expect(name == expected)
    #expect(name.map { !taken.contains($0) } == true, "a taken name is never given")
}

private func long(_ letter: String, _ count: Int, _ ending: String) -> String {
    String(repeating: letter, count: count) + ending
}

/// A long name is cut to 255 bytes of UTF-8, the extension and the clash number kept, never in the
/// middle of a character.
@Test(arguments: [
    (long("x", 300, ".pdf"), 0, ".pdf"), (long("x", 300, ".pdf"), 1, " (1).pdf"),
    (long("é", 200, ".txt"), 0, ".txt"), (long("é", 200, ".txt"), 12, " (12).txt"), (long("y", 400, ""), 3, "y (3)"),
])
func cutsALongName(suggested: String, number: Int, ending: String) {
    let name = DownloadNamer.candidate(suggested, number: number)
    #expect(name.utf8.count <= DownloadNamer.maxBytes)
    #expect(name.utf8.count >= DownloadNamer.maxBytes - 1, "cut only as far as needed: \(name.utf8.count)")
    #expect(name.hasSuffix(ending))
    #expect(String(decoding: Data(name.utf8), as: UTF8.self) == name, "whole characters only")
}

/// A short name is never cut.
@Test(arguments: [("a.pdf", 0, "a.pdf"), ("a.pdf", 2, "a (2).pdf"), ("noext", 1, "noext (1)")])
func keepsAShortName(suggested: String, number: Int, expected: String) {
    #expect(DownloadNamer.candidate(suggested, number: number) == expected)
}

/// The site's name never reaches another folder or hides a character; nothing usable gives `download`.
@Test(arguments: [
    ("../../etc/passwd", "passwd"), ("a/b.txt", "b.txt"), ("a:b.txt", "a-b.txt"), ("a\u{0}b\nc.txt", "abc.txt"),
    ("", "download"), ("...", "download"), ("   ", "download"), ("/", "download"), ("  a.pdf  ", "a.pdf"),
    ("report.pdf", "report.pdf"),
])
func cleansTheSiteName(suggested: String, expected: String) {
    #expect(DownloadNamer.clean(suggested) == expected)
    #expect(free(suggested, taken: []) == expected)
}

/// Every name taken: no name rather than a file replaced.
@Test func givesUpWhenEveryNameIsTaken() {
    var asked = 0
    let name = DownloadNamer.freeName("a.pdf", isTaken: { _ in
        asked += 1
        return true
    })
    #expect(name == nil)
    #expect(asked == DownloadNamer.maxTries + 1)
}

/// P5-BUILD-1 readback: macOS asks for ~/Downloads on the thread that first writes there; WebKit did that
/// on the main thread and the app froze. `canWrite` writes first, on the caller's thread, and leaves nothing.
@Test(arguments: [(true, true), (false, false)])
func canWriteMakesAndRemovesTheFile(writable: Bool, expected: Bool) throws {
    let folder = FileManager.default.temporaryDirectory.appendingPathComponent("nhetrinh-namer-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: false)
    defer {
        try? FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: folder.path)
        try? FileManager.default.removeItem(at: folder)
    }
    if !writable { try FileManager.default.setAttributes([.posixPermissions: 0o500], ofItemAtPath: folder.path) }
    #expect(DownloadNamer.canWrite("a.pdf", in: folder) == expected)
    #expect(try FileManager.default.contentsOfDirectory(atPath: folder.path).isEmpty, "nothing is left")
}

@Test func canWriteIsFalseWithoutTheFolder() {
    let missing = FileManager.default.temporaryDirectory.appendingPathComponent("nhetrinh-none-\(UUID().uuidString)")
    #expect(!DownloadNamer.canWrite("a.pdf", in: missing))
}
