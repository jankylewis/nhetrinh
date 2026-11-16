import Foundation
import Testing
@testable import NhetrinhCore

// P4 (hubs/product/plan/M2_REAL_SITES_WORK.md): zoom steps from 50 % to 300 %, kept per host.

/// Zoom In and Zoom Out walk the steps; 100 % -> 110 % -> 125 % (R28 reads 125 % after two).
@Test(arguments: [(1.0, 1.1), (1.1, 1.25), (0.5, 0.67), (2.5, 3.0), (1.17, 1.25), (0.3, 0.5)])
func zoomInGoesToTheNextStep(level: Double, next: Double) {
    #expect(Zoom.zoomIn(from: level) == next)
}

@Test(arguments: [(1.0, 0.9), (1.25, 1.1), (3.0, 2.5), (0.67, 0.5), (1.17, 1.1), (4.0, 3.0)])
func zoomOutGoesToThePreviousStep(level: Double, previous: Double) {
    #expect(Zoom.zoomOut(from: level) == previous)
}

/// Clamped at both ends: past 300 % and below 50 % nothing moves further.
@Test(arguments: [(3.0, true), (0.5, false)])
func zoomStopsAtTheEnds(level: Double, zoomingIn: Bool) {
    #expect((zoomingIn ? Zoom.zoomIn(from: level) : Zoom.zoomOut(from: level)) == level)
}

@Test(arguments: [(0.1, 0.5), (0.5, 0.5), (1.3, 1.3), (3.0, 3.0), (9.0, 3.0), (-1.0, 0.5), (Double.nan, 1.0)])
func levelsAreClamped(level: Double, clamped: Double) {
    #expect(Zoom.clamp(level) == clamped)
}

/// The key a level is kept under: the host in lower case, the port and the path ignored.
@Test(arguments: [
    ("https://Example.COM/a?b=1", "example.com"), ("http://127.0.0.1:8080/page/1", "127.0.0.1"),
    ("http://127.0.0.1:9090/x", "127.0.0.1"), ("https://www.example.com", "www.example.com"),
    ("about:blank", nil), ("file:///tmp/a.html", nil),
] as [(String, String?)])
func hostKeyIgnoresCaseAndPort(link: String, key: String?) throws {
    #expect(Zoom.hostKey(try #require(URL(string: link))) == key)
}

/// The badge shows only when the level is not 100 %.
@Test(arguments: [(1.0, nil), (1.25, "125 %"), (0.5, "50 %"), (0.67, "67 %"), (3.0, "300 %")] as [(Double, String?)])
func badgeShowsOnlyAwayFromActualSize(level: Double, badge: String?) {
    #expect(Zoom.badge(level) == badge)
}
