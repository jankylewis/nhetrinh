import Foundation
import Testing
@testable import NhetrinhCore

// P5 (hubs/product/plan/M2_REAL_SITES_WORK.md), red first: `DownloadList` was a stub that kept nothing.

/// The row's second line per state.
@Test(arguments: [
    (DownloadItem.State.running(0.42), "42 %"), (.running(0), "0 %"), (.running(1), "100 %"), (.running(nil), "…"),
    (.running(-1), "…"), (.running(.nan), "…"), (.finished, "done"), (.failed("no space"), "failed: no space"),
    (.cancelled, "cancelled"),
])
func showsTheState(state: DownloadItem.State, text: String) {
    #expect(DownloadItem(id: 1, name: "a", state: state).stateText == text)
}

/// Newest first; the footer shows 3; a 4th row drops the oldest that no longer runs. A running download
/// is always shown (P5-FIX-1, F2: it was kept but hidden), in its place.
@Test(arguments: [(0, ["four", "three", "two"]), (1, ["four", "three", "one"])])
func keepsTheNewestThree(running: Int, shown: [String]) {
    var list = DownloadList()
    let first = list.add("one")
    if running == 0 { list.set(first, .finished) }
    for name in ["two", "three", "four"] { list.set(list.add(name), .finished) }
    #expect(list.shownItems.map(\.name) == shown)
    #expect((list.item(first) != nil) == (running == 1), "a running download is kept and shown")
}

/// A row is found by its id, renamed and set; an unknown id changes nothing.
@Test func updatesARowByItsId() {
    var list = DownloadList()
    let a = list.add("a"), b = list.add("b")
    #expect(a != b)
    list.rename(a, "a (1).pdf")
    list.set(a, .running(0.5))
    list.set(999, .finished)
    #expect(list.item(a) == DownloadItem(id: a, name: "a (1).pdf", state: .running(0.5)))
    #expect(list.item(b)?.state == .running(nil))
    #expect(list.shownItems.map(\.id) == [b, a])
}
