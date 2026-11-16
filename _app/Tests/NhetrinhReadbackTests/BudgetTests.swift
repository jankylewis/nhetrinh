import Testing
@testable import NhetrinhReadback

/// R8 reads 5 samples 1 s apart. The GPU helper bursts to ~120 MB for 1-3 s (NT-PRF-002), so
/// R8 judges the median: a short burst must not fail it, a real growth must.
struct SamplesCase: CustomTestStringConvertible {
    let name: String
    let samples: [Budget.Sample]
    let holds: Bool

    var testDescription: String { name }
}

private let rest = Budget.Sample(app: 35, total: 95)
private let burst = Budget.Sample(app: 35, total: 215)

let samplesCases = [
    SamplesCase(name: "no burst", samples: Array(repeating: rest, count: 5), holds: true),
    SamplesCase(name: "a burst in 1 of 5", samples: [rest, rest, burst, rest, rest], holds: true),
    SamplesCase(name: "a burst in 2 of 5", samples: [burst, rest, rest, rest, burst], holds: true),
    SamplesCase(name: "a burst in 3 of 5", samples: [burst, burst, rest, burst, rest], holds: false),
    SamplesCase(name: "the total grows in every sample", samples: (0..<5).map {
        Budget.Sample(app: 35, total: 111 + Double($0))
    }, holds: false),
    SamplesCase(name: "the app grows in every sample", samples: (0..<5).map {
        Budget.Sample(app: 41 + Double($0), total: 100)
    }, holds: false),
    SamplesCase(name: "the app bursts in 1 of 5", samples: [rest, Budget.Sample(app: 90, total: 150), rest, rest, rest],
                holds: true),
    SamplesCase(name: "no sample", samples: [], holds: false),
]

@Test(arguments: samplesCases)
func memoryBudgetJudgesTheMedian(run: SamplesCase) {
    #expect(Budget.Reading(run.samples).holds == run.holds)
}

@Test func readingKeepsTheHighestSample() {
    let reading = Budget.Reading([rest, burst, rest, Budget.Sample(app: 38, total: 96), rest])
    #expect(reading.app == 35 && reading.total == 95)
    #expect(reading.highestApp == 38 && reading.highestTotal == 215)
}
