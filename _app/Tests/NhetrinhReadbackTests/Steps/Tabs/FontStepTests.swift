import Testing
@testable import NhetrinhReadback

// P8-FONT-1, R47: which controls the probe says are not in Menlo. A control the probe did not read is
// named too: it is never taken as Menlo. Red first.

private let all = Dictionary(uniqueKeysWithValues: FontStep.controls.map { ($0, "Menlo") })

@Test(arguments: [
    (all, []),
    (all.merging(["address bar": "Helvetica"]) { $1 }, ["address bar: Helvetica"]),
    (all.merging(["find bar": "mixed: .SF NS, Menlo"]) { $1 }, ["find bar: mixed: .SF NS, Menlo"]),
    (all.filter { $0.key != "folder row" }, ["folder row: not read"]),
    ([:], FontStep.controls.map { "\($0): not read" }),
] as [([String: String], [String])])
func fontStepNamesEveryControlNotInMenlo(fonts: [String: String], wrong: [String]) {
    #expect(FontStep.wrong(fonts) == wrong)
}

@Test func fontStepReadsTheMainControls() {
    #expect(FontStep.controls == ["sidebar row", "folder row", "New Tab", "address bar", "find bar", "Settings Hub"])
    #expect(FontStep.step.id == "R47")
}
