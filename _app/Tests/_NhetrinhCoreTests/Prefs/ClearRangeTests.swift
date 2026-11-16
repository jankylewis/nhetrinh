import Foundation
import Testing
@testable import NhetrinhCore

// P4P6-FIX-1 (REVIEW_P4_P6 F1, F6), red first on a stub that mapped no button: R30 cannot tell Clear All
// from Clear Last Hour (its cookie is seconds old), so the mapping is proven here.

private let now = Date(timeIntervalSinceReferenceDate: 1_000_000)

/// Button order as the sheet shows it; Cancel first (the default).
@Test func theSheetButtons() {
    #expect(ClearRange.buttons == ["Cancel", "Clear Last Hour", "Clear All"])
}

/// Each button by its index; Cancel and an index past the buttons remove nothing.
@Test(arguments: [(0, nil), (1, ClearRange.lastHour), (2, .all), (3, nil), (-1, nil)] as [(Int, ClearRange?)])
func aButtonGivesItsRange(index: Int, range: ClearRange?) {
    #expect(ClearRange(button: index) == range)
}

/// Clear Last Hour removes data of the last 3600 s only; Clear All everything, and the per-site settings.
@Test(arguments: [(ClearRange.lastHour, now - 3600, false), (.all, Date.distantPast, true)])
func aRangeRemovesSince(range: ClearRange, since: Date, sites: Bool) {
    #expect(range.since(now: now) == since)
    #expect(range.forgetsSiteSettings == sites)
}
