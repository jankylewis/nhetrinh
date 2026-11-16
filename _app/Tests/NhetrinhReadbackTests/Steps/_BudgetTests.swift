import Testing
@testable import NhetrinhReadback

/// R8 reads 9 samples 1 s apart. The GPU helper bursts to ~120 MB for 1-3 s (NT-PRF-002), so the
/// total is judged on its median (a burst covers at most 3 of 9) and fails on a rise: the last 4
/// samples all over the budget. The app process is judged on its highest sample.
struct SamplesCase: CustomTestStringConvertible {
    let name: String
    let samples: [Budget.Sample]
    let holds: Bool

    var testDescription: String { name }
}

private let rest = Budget.Sample(app: 35, total: 95)
private let burst = Budget.Sample(app: 35, total: 215)

/// `Budget.sampleCount` samples at rest, with `changed` put in at the given indexes.
private func nine(_ changed: [Int: Budget.Sample] = [:]) -> [Budget.Sample] {
    (0..<Budget.sampleCount).map { changed[$0] ?? rest }
}

private func totals(_ values: [Double]) -> [Budget.Sample] { values.map { Budget.Sample(app: 35, total: $0) } }

let samplesCases = [
    SamplesCase(name: "no burst", samples: nine(), holds: true),
    SamplesCase(name: "a burst in 1 of 9", samples: nine([4: burst]), holds: true),
    SamplesCase(name: "two 1 s bursts", samples: nine([0: burst, 8: burst]), holds: true),
    SamplesCase(name: "a burst in 5 of 9", samples: nine([0: burst, 2: burst, 4: burst, 6: burst, 7: burst]),
                holds: false),
    SamplesCase(name: "the total over the budget in every sample", samples: (0..<9).map {
        Budget.Sample(app: 35, total: 111 + Double($0))
    }, holds: false),
    SamplesCase(name: "the app over the budget in every sample", samples: (0..<9).map {
        Budget.Sample(app: 41 + Double($0), total: 100)
    }, holds: false),
    // This case once expected a pass (judged on the median). It must fail now: no app-process
    // burst was ever seen (hubs/failures/evidence/prf/NT_PRF_002_GPU_SAMPLES.jsonl has bursts in
    // the GPU helper only), so an app sample over 40 MB is a real cost, judged on the highest sample.
    SamplesCase(name: "the app bursts in 1 of 9", samples: nine([1: Budget.Sample(app: 90, total: 150)]),
                holds: false),
    SamplesCase(name: "the app at the budget in every sample", samples: (0..<9).map { _ in
        Budget.Sample(app: 40, total: 110)
    }, holds: true),
    SamplesCase(name: "no sample", samples: [], holds: false),
]

@Test(arguments: samplesCases)
func memoryBudgetJudgesTheSamples(run: SamplesCase) {
    #expect(Budget.Reading(run.samples).holds == run.holds)
}

@Test func readingKeepsTheHighestSample() {
    let reading = Budget.Reading([rest, burst, rest, Budget.Sample(app: 38, total: 96), rest])
    #expect(reading.app == 35 && reading.total == 95)
    #expect(reading.highestApp == 38 && reading.highestTotal == 215)
}

@Test func r8ReadsNineSamples() {
    #expect(Budget.sampleCount == 9 && Budget.risingCount == 4)
}

/// The R8 line names what is judged: the app on its highest sample, the total on its median and the last-4 rule.
@Test func r8LineNamesWhatIsJudged() {
    let line = Budget.Reading(nine([1: Budget.Sample(app: 38, total: 96), 8: burst])).line(helpers: 4)
    #expect(line == "app judged on the highest of 9 samples 1 s apart: 38.0 MB (max 40); app + 4 helpers judged "
            + "on the median of 9: 95.0 MB (max 110), highest 215.0 MB; last 4 samples all over 110 MB: no")
}

/// P0-REV-1 gaps. The burst shape is real: hubs/failures/evidence/prf/NT_PRF_002_GPU_SAMPLES.jsonl
/// has bursts of 3 consecutive samples in runs 1, 6 and 7. No app-process burst was ever seen there.
let reviewSamplesCases = [
    SamplesCase(name: "one 3 s GPU burst (3 consecutive samples)", samples: nine([3: burst, 4: burst, 5: burst]),
                holds: true),
    SamplesCase(name: "one 3 s GPU burst in the last 3 samples", samples: nine([6: burst, 7: burst, 8: burst]),
                holds: true),
    SamplesCase(name: "the total grows across the budget", samples: (0..<9).map {
        Budget.Sample(app: 35, total: 100 + 4 * Double($0))
    }, holds: false),
    SamplesCase(name: "the total rises over the budget in the last 4 samples",
                samples: totals([95, 95, 95, 95, 95, 111, 112, 113, 114]), holds: false),
    SamplesCase(name: "the total over the budget in the last 4 samples but one",
                samples: totals([95, 95, 95, 95, 95, 111, 112, 100, 114]), holds: true),
    SamplesCase(name: "the app process over budget in 2 of 9", samples: nine([
        1: Budget.Sample(app: 45, total: 100), 3: Budget.Sample(app: 45, total: 100),
    ]), holds: false),
]

@Test(arguments: reviewSamplesCases)
func memoryBudgetReviewGaps(run: SamplesCase) {
    #expect(Budget.Reading(run.samples).holds == run.holds)
}

/// P0-REV-2 gap. `memorySamples` writes app 0 (and the total of what is left) when the app process
/// is not found: the app quit or crashed while R8 read. Those zeros pull the median down and pass.
/// A sample without the app is no reading, and no reading is never a pass (NOT READ BACK).
let missingAppCases = [
    SamplesCase(name: "the app is gone after 4 samples over the budget", samples: [
        Budget.Sample(app: 35, total: 200), Budget.Sample(app: 35, total: 200), Budget.Sample(app: 35, total: 200),
        Budget.Sample(app: 35, total: 200),
    ] + Array(repeating: Budget.Sample(app: 0, total: 0), count: 5), holds: false),
    SamplesCase(name: "the app is missing in 1 of 9", samples: nine([4: Budget.Sample(app: 0, total: 0)]),
                holds: false),
]

@Test(arguments: missingAppCases)
func memoryBudgetNeedsTheAppInEverySample(run: SamplesCase) {
    #expect(Budget.Reading(run.samples).holds == run.holds)
}

/// P6, R38: 3 tabs opened, 2 unloaded, cost the one-tab budget + 15 MB (app 55, app + helpers 125).
@Test(arguments: [
    (Budget.Sample(app: 54, total: 124), 15.0, true), (Budget.Sample(app: 56, total: 100), 15.0, false),
    (Budget.Sample(app: 35, total: 126), 15.0, false), (Budget.Sample(app: 54, total: 124), 0.0, false),
])
func theBudgetTakesAnAllowance(sample: Budget.Sample, extra: Double, holds: Bool) {
    let reading = Budget.Reading(Array(repeating: sample, count: Budget.sampleCount), extra: extra)
    #expect(reading.holds == holds && Budget.pressureExtra == 15)
}
