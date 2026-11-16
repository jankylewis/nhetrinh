/// The lightness budget (hubs/product/plan/_PLAN.md). A phase that breaks it stops.
enum Budget {
    static let appMegabytes = 40.0
    static let totalMegabytes = 110.0
    static let bundleKilobytes = 1024
    static let idleCpuPercent = 2.0

    /// R8 reads this many memory samples, 1 s apart, after the page has settled.
    static let sampleCount = 5

    /// One memory sample: the app process, and the app with every helper process.
    struct Sample {
        let app: Double
        let total: Double
    }

    /// The memory verdict of R8. WebKit's GPU helper bursts to ~120 MB for 1-3 s (NT-PRF-002),
    /// so R8 judges the MEDIAN of the samples: a short burst does not fail it, a real growth
    /// does. The highest sample is kept to be shown, so a burst is still seen.
    struct Reading {
        let app: Double
        let total: Double
        let highestApp: Double
        let highestTotal: Double
        let count: Int

        init(_ samples: [Sample]) {
            app = median(samples.map(\.app))
            total = median(samples.map(\.total))
            highestApp = samples.map(\.app).max() ?? 0
            highestTotal = samples.map(\.total).max() ?? 0
            count = samples.count
        }

        /// No sample is never a pass.
        var holds: Bool { count > 0 && app <= Budget.appMegabytes && total <= Budget.totalMegabytes }
    }
}

/// The middle value; the mean of the two middle values for an even count; 0 for none.
func median(_ values: [Double]) -> Double {
    let sorted = values.sorted()
    guard !sorted.isEmpty else { return 0 }
    let middle = sorted.count / 2
    return sorted.count % 2 == 1 ? sorted[middle] : (sorted[middle - 1] + sorted[middle]) / 2
}
