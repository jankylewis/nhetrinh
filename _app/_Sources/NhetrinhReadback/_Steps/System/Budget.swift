import Foundation

/// The lightness budget (hubs/product/plan/_PLAN.md). A phase that breaks it stops.
enum Budget {
    static let appMegabytes = 40.0
    static let totalMegabytes = 110.0
    static let bundleKilobytes = 1024
    static let idleCpuPercent = 2.0
    /// R38 (P6): 3 tabs opened and 2 of them unloaded cost the one-tab budget + this, for the app
    /// and for the app with its helpers.
    static let pressureExtra = 15.0

    /// R8 reads this many memory samples, 1 s apart, after the page has settled. A GPU burst
    /// lasts at most 3 s (NT-PRF-002), so it covers at most 3 of 9 and cannot move the median.
    static let sampleCount = 9

    /// The total also fails when this many last samples are all over the budget: a rise that
    /// lasts longer than any burst seen.
    static let risingCount = 4

    /// One memory sample: the app process, and the app with every helper process. `app` is 0 when
    /// the app process was not found (it quit or crashed while R8 read): such a sample is no reading.
    struct Sample {
        let app: Double
        let total: Double
    }

    /// The memory verdict of R8. WebKit's GPU helper bursts to ~120 MB for 1-3 s (NT-PRF-002),
    /// so the TOTAL is judged on its median, and fails on a rise (the last `risingCount` samples
    /// over). The APP process is judged on its highest sample: no app-process burst was ever seen.
    struct Reading {
        let app: Double
        let total: Double
        let highestApp: Double
        let highestTotal: Double
        let count: Int
        let rises: Bool
        /// Samples without the app process. Their zeros would pull the median down and pass (P0-REV-2).
        let missingApp: Int
        /// The budgets judged: the one-tab budget, + `extra` for R38's 3 tabs with 2 unloaded (P6).
        let appLimit: Double
        let totalLimit: Double

        init(_ samples: [Sample], extra: Double = 0) {
            appLimit = Budget.appMegabytes + extra
            let totalLimit = Budget.totalMegabytes + extra
            self.totalLimit = totalLimit
            missingApp = samples.filter { $0.app <= 0 }.count
            app = median(samples.map(\.app))
            total = median(samples.map(\.total))
            highestApp = samples.map(\.app).max() ?? 0
            highestTotal = samples.map(\.total).max() ?? 0
            count = samples.count
            let last = samples.suffix(Budget.risingCount)
            rises = last.count == Budget.risingCount && last.allSatisfy { $0.total > totalLimit }
        }

        /// The R8 (and R38) line: what is judged, on which samples, against which budget.
        func line(helpers: Int) -> String {
            String(format: "app judged on the highest of %d samples 1 s apart: %.1f MB (max %.0f); "
                   + "app + %d helpers judged on the median of %d: %.1f MB (max %.0f), highest %.1f MB; "
                   + "last %d samples all over %.0f MB: %@", count, highestApp, appLimit, helpers, count,
                   total, totalLimit, highestTotal, Budget.risingCount, totalLimit,
                   rises ? "yes" : "no")
        }

        /// Why this is no reading (R8 says NOT READ BACK); nil when every sample has the app.
        var noReading: String? {
            if count == 0 { return "no memory sample was read" }
            guard missingApp > 0 else { return nil }
            return "the app process was missing in \(missingApp) of \(count) memory samples (it quit or crashed)"
        }

        /// No sample, or a sample without the app, is never a pass.
        var holds: Bool {
            noReading == nil && highestApp <= appLimit && total <= totalLimit && !rises
        }
    }
}

/// The middle value; the mean of the two middle values for an even count; 0 for none.
func median(_ values: [Double]) -> Double {
    let sorted = values.sorted()
    guard !sorted.isEmpty else { return 0 }
    let middle = sorted.count / 2
    return sorted.count % 2 == 1 ? sorted[middle] : (sorted[middle - 1] + sorted[middle]) / 2
}
