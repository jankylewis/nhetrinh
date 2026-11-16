import Foundation
import Testing
@testable import NhetrinhReadback

/// NT-GAT-006: R6 held a sidebar row across a navigation; the reload made it invalid (-25202).
/// A step now finds its row by index in a fresh read and acts once more after a short wait.
struct RowIndexCase: CustomTestStringConvertible {
    let fromEnd: Int
    let count: Int
    let index: Int?

    var testDescription: String { "\(fromEnd) from the end of \(count) rows" }
}

@Test("the row counted from the end", arguments: [
    RowIndexCase(fromEnd: 0, count: 2, index: 1),
    RowIndexCase(fromEnd: 1, count: 2, index: 0),
    RowIndexCase(fromEnd: 1, count: 5, index: 3),
    RowIndexCase(fromEnd: 2, count: 2, index: nil),
    RowIndexCase(fromEnd: 0, count: 0, index: nil),
    RowIndexCase(fromEnd: -1, count: 3, index: nil),
])
func rowIndexFromEnd(_ row: RowIndexCase) {
    #expect(Fresh.rowIndex(fromEnd: row.fromEnd, count: row.count) == row.index)
}

/// What each call of the act does: succeed, or throw as a stale element or a wrong app does.
enum Outcome { case ok, stale, wrong }

struct RetryCase: CustomTestStringConvertible {
    let name: String
    let outcomes: [Outcome]
    let calls: Int
    let sleeps: Int
    let verdict: String

    var testDescription: String { name }
}

private func run(_ outcomes: [Outcome]) -> (calls: Int, sleeps: Int, verdict: String) {
    var calls = 0, sleeps = 0
    do {
        try Fresh.retryingOnce(wait: 0.3, sleep: { _ in sleeps += 1 }) {
            calls += 1
            switch outcomes[min(calls, outcomes.count) - 1] {
            case .ok: return
            case .stale: throw StepError.cannotDrive("cannot set AXSelected (accessibility error -25202)")
            case .wrong: throw StepError.fail("wrong tab")
            }
        }
        return (calls, sleeps, "pass")
    } catch StepError.cannotDrive(let why) {
        return (calls, sleeps, why.hasSuffix("again after a fresh lookup") ? "cannot drive, retried" : why)
    } catch {
        return (calls, sleeps, "fail")
    }
}

@Test("a stale element gets one more fresh try, nothing else does", arguments: [
    RetryCase(name: "acts at once", outcomes: [.ok], calls: 1, sleeps: 0, verdict: "pass"),
    RetryCase(name: "stale, then fresh", outcomes: [.stale, .ok], calls: 2, sleeps: 1, verdict: "pass"),
    RetryCase(name: "stale twice", outcomes: [.stale, .stale, .ok], calls: 2, sleeps: 1,
              verdict: "cannot drive, retried"),
    RetryCase(name: "the app is wrong", outcomes: [.wrong, .ok], calls: 1, sleeps: 0, verdict: "fail"),
    RetryCase(name: "stale, then wrong", outcomes: [.stale, .wrong], calls: 2, sleeps: 1, verdict: "fail"),
])
func retryingOnce(_ retry: RetryCase) {
    let seen = run(retry.outcomes)
    #expect(seen.calls == retry.calls)
    #expect(seen.sleeps == retry.sleeps)
    #expect(seen.verdict == retry.verdict)
}
