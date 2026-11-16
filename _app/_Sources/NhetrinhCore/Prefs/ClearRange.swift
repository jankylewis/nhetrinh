import Foundation

// P4P6-FIX-1 (REVIEW_P4_P6 F1, F6); tests in Tests/_NhetrinhCoreTests/Prefs/ClearRangeTests.swift.

/// Clear Website Data…: the sheet's buttons, in order, and what each one removes. A pure mapping, so the
/// button that removes everything is tested here: the readback (R30) cannot tell the two apart.
public enum ClearRange: Equatable, Sendable {
    case lastHour, all

    /// The sheet's buttons; the first, Cancel, is the default and removes nothing.
    public static let buttons = ["Cancel", "Clear Last Hour", "Clear All"]

    /// The range of the button at `index` (0 first); nil for Cancel or no button.
    public init?(button index: Int) {
        switch index {
        case 1: self = .lastHour
        case 2: self = .all
        default: return nil
        }
    }

    /// Website data modified since this date is removed.
    public func since(now: Date) -> Date { self == .all ? .distantPast : now.addingTimeInterval(-3600) }

    /// Whether the per-site settings in `prefs.json` go too (the zoom per host: F6 ruling). They carry no
    /// date, so Clear Last Hour keeps them.
    public var forgetsSiteSettings: Bool { self == .all }
}
