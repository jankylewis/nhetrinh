import Foundation

// P11-HISTORY (D30); tests in Tests/_NhetrinhCoreTests/_Navigation/_Address/History/FrecencyTests.swift.

/// How a page ranks (Firefox-like, simple): score = (visits + 2 x typed) x the weight of its last visit's age.
/// The store ranks in SQL with the same numbers (`sql`), so one table decides both.
public enum Frecency {
    /// Age at most `days` days: `weight`; youngest first. Older than the last: `older`.
    public static let steps: [(days: Double, weight: Double)] = [(4, 1.0), (14, 0.7), (31, 0.5), (90, 0.3)]
    public static let older = 0.1
    static let day: TimeInterval = 86_400

    /// The weight of a last visit at `lastVisit`, seen at `now` (a date ahead of `now` counts as today).
    public static func weight(lastVisit: Date, now: Date) -> Double {
        let age = now.timeIntervalSince(lastVisit)
        return steps.first { age <= $0.days * day }?.weight ?? older
    }

    public static func score(visits: Int, typed: Int, lastVisit: Date, now: Date) -> Double {
        Double(visits + 2 * typed) * weight(lastVisit: lastVisit, now: now)
    }

    /// The score as an SQL expression over the columns `visits`, `typed` and `last_visit` (seconds since 1970).
    /// Only numbers of this file go in: nothing typed reaches the text.
    static func sql(now: Date) -> String {
        let cases = steps.map { "WHEN last_visit >= \(now.timeIntervalSince1970 - $0.days * day) THEN \($0.weight)" }
        return "((visits + 2 * typed) * (CASE \(cases.joined(separator: " ")) ELSE \(older) END))"
    }
}
