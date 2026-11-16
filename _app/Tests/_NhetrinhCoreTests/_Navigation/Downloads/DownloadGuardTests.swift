import Darwin
import Foundation
import Testing
@testable import NhetrinhCore

// P5-FIX-1 (rulings on nhetrinh_wt/REVIEW_P5.md), red first: names (F8, F10), every running row (F2),
// stalled (F9), a page's unclicked downloads (F2), quarantine (F5).

/// F10: no hidden file in ~/Downloads: leading dots (and the spaces after them) go.
@Test(arguments: [(".env", "env"), ("..hidden.txt", "hidden.txt"), (". a.pdf", "a.pdf"), (".", "download"),
                  ("a.b", "a.b")])
func aLeadingDotIsRemoved(suggested: String, expected: String) {
    #expect(DownloadNamer.clean(suggested) == expected)
}

/// F8: ~/Downloads (APFS, default) does not tell case or Unicode normalization apart: neither may two names.
@Test(arguments: [("Report.pdf", "report.pdf", true), ("caf\u{E9}.txt", "cafe\u{301}.txt", true),
                  ("a.pdf", "b.pdf", false), ("a.pdf", "a.pdf.download", false)])
func sameFileIgnoresCaseAndNormalization(one: String, other: String, same: Bool) {
    #expect((DownloadNamer.key(one) == DownloadNamer.key(other)) == same)
}

/// F1, F6: a download is written under `<name>.download` and gets its name only when it is complete.
@Test func aPartialFileHasItsOwnName() {
    #expect(DownloadNamer.partial("a.pdf") == "a.pdf.download")
}

private let start = Date(timeIntervalSinceReferenceDate: 1_000)

/// F2: every running download has a row (the footer scrolls); finished ones fill up to 3.
@Test(arguments: [(5, 0, 5), (1, 4, 3), (0, 5, 3), (4, 2, 4)])
func everyRunningDownloadHasARow(running: Int, ended: Int, rows: Int) {
    var list = DownloadList()
    for index in 0..<ended { list.set(list.add("ended \(index)", at: start), .finished) }
    for index in 0..<running { list.add("running \(index)", at: start) }
    let shownRunning = list.shownItems.filter { if case .running = $0.state { return true } else { return false } }
    #expect(list.shownItems.count == rows && shownRunning.count == running)
}

/// F9: a running download with no new bytes for 60 s reads "stalled"; new bytes end it; an ended one never.
@Test(arguments: [(59.0, false), (60.0, true), (600.0, true)])
func noBytesForAMinuteIsStalled(quiet: TimeInterval, stalled: Bool) {
    var list = DownloadList()
    let id = list.add("a.zip", at: start)
    list.progressed(id, 0.1, at: start + 5)
    #expect(list.markStalls(now: start + 5 + quiet) == stalled)
    #expect(list.item(id)?.stateText == (stalled ? "stalled" : "10 %"))
    list.progressed(id, 0.2, at: start + 5 + quiet + 1)
    #expect(list.item(id)?.stateText == "20 %")
    list.set(id, .finished)
    #expect(!list.markStalls(now: start + 10_000) && list.item(id)?.stateText == "done")
}

/// F2: a page gets 5 downloads it started without a click; the 6th asks. A click is never counted.
@Test(arguments: [(5, DownloadGate.Decision.go), (6, .ask)])
func unclickedDownloadsAskPastFive(count: Int, last: DownloadGate.Decision) {
    var gate = DownloadGate()
    let decisions = (0..<count).map { _ in gate.decide(page: "p", clicked: false) }
    #expect(decisions.dropLast().allSatisfy { $0 == .go } && decisions.last == last)
    #expect(gate.decide(page: "p", clicked: true) == .go && gate.decide(page: "other", clicked: false) == .go)
}

/// The answer holds for that page: Allow lets the rest go, Don't Allow refuses them.
@Test(arguments: [(true, DownloadGate.Decision.go), (false, .refuse)])
func theAnswerHoldsForThePage(allowed: Bool, then: DownloadGate.Decision) {
    var gate = DownloadGate()
    for _ in 0..<6 { _ = gate.decide(page: "p", clicked: false) }
    gate.answer(page: "p", allowed: allowed)
    #expect(gate.decide(page: "p", clicked: false) == then && gate.decide(page: "q", clicked: false) == .go)
}

/// A click counts for `clickWindow` seconds after the user's last mouse or key event in the page.
@Test(arguments: [(Double?.none, false), (0.0, true), (4.9, true), (5.1, false)])
func aDownloadSoonAfterAClickIsClicked(ago: Double?, clicked: Bool) {
    #expect(DownloadGate.isClicked(lastInput: ago.map { start - $0 }, now: start) == clicked)
}

/// F5: a finished download carries macOS's quarantine, as Safari's do: read back from the file itself.
@Test func aFinishedDownloadIsQuarantined() throws {
    let file = FileManager.default.temporaryDirectory.appendingPathComponent("nhetrinh-qtn-\(UUID()).zip")
    try Data("zip".utf8).write(to: file)
    defer { try? FileManager.default.removeItem(at: file) }
    let source = try #require(URL(string: "https://example.com/a.zip"))
    try Quarantine.mark(file, source: source, page: URL(string: "https://example.com/"))
    var raw = [CChar](repeating: 0, count: 256)
    let size = getxattr(file.path, "com.apple.quarantine", &raw, raw.count, 0, 0)
    let value = size > 0 ? String(decoding: raw.prefix(size).map { UInt8(bitPattern: $0) }, as: UTF8.self) : ""
    // "<flags>;<time>;<agent>;<id>": the agent is filled in by macOS from the calling app (empty in a test).
    #expect(value.split(separator: ";", omittingEmptySubsequences: false).count == 4, "com.apple.quarantine: \(value)")
    let properties = try file.resourceValues(forKeys: [.quarantinePropertiesKey]).quarantineProperties
    #expect(properties?["LSQuarantineType"] as? String == "LSQuarantineTypeWebDownload")
}
