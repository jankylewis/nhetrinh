import Foundation

/// The lightness budget (hubs/product/plan/_PLAN.md). A phase that breaks it stops.
enum Budget {
    static let appMegabytes = 40.0
    static let totalMegabytes = 110.0
    static let bundleKilobytes = 1024
    static let idleCpuPercent = 2.0

    /// R8 reads this many memory samples, 1 s apart, after the page has settled. A GPU burst
    /// lasts at most 3 s (NT-PRF-002), so it covers at most 3 of 9 and cannot move the median.
    static let sampleCount = 9

    /// The total also fails when this many last samples are all over the budget: a rise that
    /// lasts longer than any burst seen.
    static let risingCount = 4

    /// One memory sample: the app process, and the app with every helper process.
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

        init(_ samples: [Sample]) {
            app = median(samples.map(\.app))
            total = median(samples.map(\.total))
            highestApp = samples.map(\.app).max() ?? 0
            highestTotal = samples.map(\.total).max() ?? 0
            count = samples.count
            let last = samples.suffix(Budget.risingCount)
            rises = last.count == Budget.risingCount && last.allSatisfy { $0.total > Budget.totalMegabytes }
        }

        /// The R8 line: what is judged, on which samples, against which budget.
        func line(helpers: Int) -> String {
            String(format: "app judged on the highest of %d samples 1 s apart: %.1f MB (max %.0f); "
                   + "app + %d helpers judged on the median of %d: %.1f MB (max %.0f), highest %.1f MB; "
                   + "last %d samples all over %.0f MB: %@", count, highestApp, Budget.appMegabytes, helpers, count,
                   total, Budget.totalMegabytes, highestTotal, Budget.risingCount, Budget.totalMegabytes,
                   rises ? "yes" : "no")
        }

        /// No sample is never a pass.
        var holds: Bool {
            count > 0 && highestApp <= Budget.appMegabytes && total <= Budget.totalMegabytes && !rises
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
