import Foundation
import Testing
@testable import NhetrinhCore

/// P11-HISTORY (D30): score = (visits + 2 x typed) x recency weight; the store ranks by the same score, a host
/// prefix first. A query on 5,000 pages answers in under 10 ms.
struct FrecencyTests {
    @Test(arguments: [
        (days: 0.0, weight: 1.0), (days: 4.0, weight: 1.0), (days: 4.01, weight: 0.7), (days: 14.0, weight: 0.7),
        (days: 14.5, weight: 0.5), (days: 31.0, weight: 0.5), (days: 31.5, weight: 0.3), (days: 90.0, weight: 0.3),
        (days: 90.5, weight: 0.1), (days: 900.0, weight: 0.1), (days: -2.0, weight: 1.0),
    ])
    func theRecencyWeight(days: Double, weight: Double) {
        #expect(Frecency.weight(lastVisit: HistoryRig.daysAgo(days), now: HistoryRig.now) == weight)
    }

    @Test(arguments: [
        (visits: 1, typed: 0, days: 1.0, score: 1.0), (visits: 3, typed: 1, days: 1.0, score: 5.0),
        (visits: 3, typed: 1, days: 20.0, score: 2.5), (visits: 10, typed: 0, days: 200.0, score: 1.0),
        (visits: 2, typed: 2, days: 10.0, score: 4.2),
    ])
    func theScore(visits: Int, typed: Int, days: Double, score: Double) {
        let found = Frecency.score(visits: visits, typed: typed,
                                   lastVisit: HistoryRig.daysAgo(days), now: HistoryRig.now)
        #expect(abs(found - score) < 1e-9)
    }

    /// The store's order is the score's: typed beats visited, recent beats old.
    @Test func theStoreRanksByTheScore() throws {
        let store = try HistoryRig.store()
        try HistoryRig.visit(store, "https://a.test/page", title: "page", times: 3, timing: (typed: 0, days: 1))
        try HistoryRig.visit(store, "https://b.test/page", title: "page", times: 2, timing: (typed: 1, days: 1))
        try HistoryRig.visit(store, "https://c.test/page", title: "page", times: 9, timing: (typed: 0, days: 40))
        try HistoryRig.visit(store, "https://d.test/page", title: "page", times: 1, timing: (typed: 0, days: 0))
        let expected = ["https://b.test/page", "https://a.test/page", "https://c.test/page", "https://d.test/page"]
        #expect(try HistoryRig.urls(store, "page") == expected)
        let scores = try store.suggestions(for: "page", now: HistoryRig.now).map {
            Frecency.score(visits: $0.visits, typed: $0.typed, lastVisit: $0.lastVisit, now: HistoryRig.now)
        }
        #expect(scores == scores.sorted(by: >))
    }

    /// A host that starts with what was typed comes first, even with a lower score.
    @Test(arguments: ["exa", "example.t", "www.exa", "https://exa", "https://www.example.test/do"])
    func aHostPrefixRanksFirst(typed: String) throws {
        let store = try HistoryRig.store()
        try HistoryRig.visit(store, "https://search.test/?q=example", title: "example", times: 20,
                             timing: (typed: 5, days: 0))
        try HistoryRig.visit(store, "https://www.example.test/docs", title: "Docs", timing: (typed: 0, days: 60))
        #expect(try HistoryRig.urls(store, typed).first == "https://www.example.test/docs")
    }

    /// The headmate's report: `https` shows the visited sites, the best first.
    @Test func httpsShowsTheVisitedSites() throws {
        let store = try HistoryRig.store()
        try HistoryRig.visit(store, "https://one.test/", times: 1)
        try HistoryRig.visit(store, "https://two.test/", times: 4)
        try HistoryRig.visit(store, "http://plain.test/", times: 9)
        #expect(try HistoryRig.urls(store, "https") == ["https://two.test/", "https://one.test/"])
    }

    @Test func aQueryOnFiveThousandPagesTakesUnderTenMilliseconds() throws {
        let store = try HistoryRig.store()
        try store.fill(count: HistoryStore.capacity, now: HistoryRig.now)
        #expect(store.count == HistoryStore.capacity)
        for typed in ["h", "https", "site 42", "page title 4999", "zzz", "site4"] {
            var times: [TimeInterval] = []
            for _ in 0..<5 {
                let start = Date()
                _ = try store.suggestions(for: typed, now: HistoryRig.now)
                times.append(Date().timeIntervalSince(start))
            }
            let median = times.sorted()[2]
            #expect(median < 0.010, "\"\(typed)\": median \(median * 1000) ms")
        }
    }
}

extension HistoryStore {
    /// `count` synthetic pages (site<n>.test) in one transaction: the query-time test's 5,000 rows.
    func fill(count: Int, now: Date) throws {
        try database.run("BEGIN")
        for index in 0..<count {
            let url = "https://site\(index).test/path/\(index)"
            try record(url: url, title: "Page title \(index)", typed: index % 7 == 0,
                       at: now.addingTimeInterval(-Double(index) * 3_600))
        }
        try database.run("COMMIT")
    }
}
