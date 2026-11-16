import Foundation
import Testing
@testable import NhetrinhCore

// P5-REVIEW (nhetrinh_wt/REVIEW_P5.md): red on origin/p5/downloads e7dccf9. No fix here.

/// A page can start any number of downloads (`<a download>` clicked by script needs no click of the
/// user). The footer shows 3 rows and Cancel is on a shown row only: a 4th running download is kept but
/// never shown, so nothing in the app can stop it before it ends or the app quits.
@Test(arguments: [4, 100])
func everyRunningDownloadCanBeCancelled(count: Int) {
    var list = DownloadList()
    for index in 1...count { list.add("file \(index)") }
    let running = list.items.filter { if case .running = $0.state { return true } else { return false } }
    #expect(running.allSatisfy { item in list.shownItems.contains { $0.id == item.id } },
            "\(running.count) running, \(list.shownItems.count) shown with a Cancel")
}

/// A line or paragraph separator is not a control character (Zl, Zp), so `clean` keeps it: the file name
/// in Finder and the footer row break over two lines, as a `\n` would (which `clean` removes).
@Test(arguments: [("a\u{2028}b.txt", "ab.txt"), ("a\u{2029}b.txt", "ab.txt")])
func cleanRemovesLineBreakingSeparators(suggested: String, expected: String) {
    #expect(DownloadNamer.clean(suggested) == expected)
}
