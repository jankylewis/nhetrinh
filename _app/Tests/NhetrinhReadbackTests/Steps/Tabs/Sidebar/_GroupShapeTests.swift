import NhetrinhCore
import Testing
@testable import NhetrinhReadback

// P8-GROUPS-FIX-1 (REVIEW_P8_GROUPS, defect 1): R49 must FAIL when a reopen, a move back or an ungroup
// puts a tab or a group in the wrong place, even when the group paths and the tab order read right.

private func page(_ page: Int) -> String { GroupDriving.page(page) }

/// The probe's answer for a tree that reads `shape` exactly.
private func state(_ shape: GroupShape) -> ProbeState {
    var state = ProbeState()
    state.groupPaths = shape.paths
    state.groupCounts = shape.counts
    state.folderTabs = shape.ownTabs.map { $0.map(page) }
    state.rows = shape.rows
    state.rowLevels = shape.levels
    state.tabTitles = (1...5).map(page)
    return state
}

/// A broken reopen: Feedback entry made again, empty, and page 5 at the top level's end. Its paths and its
/// tab order are those of the good tree.
private let reopenedAtTheEnd: ProbeState = {
    var broken = state(.ungrouped)
    broken.groupCounts = [3, 1, 0]
    broken.folderTabs = [[page(2), page(3)], [page(4)], []]
    broken.rowLevels = [0, 0, 1, 1, 1, 2, 2, 0]
    return broken
}()

/// A broken move back: the paths read right, but FE counts only its own tab, not the 2 in Pull requests.
private let movedBackCountedWrong: ProbeState = {
    var broken = state(.renamed)
    broken.groupCounts = [4, 1, 2, 1]
    return broken
}()

/// A broken ungroup: page 3 left at the top level's end.
private let ungroupedOutOfWork: ProbeState = {
    var broken = state(.ungrouped)
    broken.groupCounts = [3, 2, 1]
    broken.folderTabs = [[page(2)], [page(4)], [page(5)]]
    broken.rows = [page(1), "Work", page(2), "Pull requests", page(4), "Feedback entry", page(5), page(3)]
    return broken
}()

@Test(arguments: [
    (reopenedAtTheEnd, GroupShape.ungrouped, "tab counts [3, 1, 0], not [4, 2, 1]"),
    (movedBackCountedWrong, GroupShape.renamed, "tab counts [4, 1, 2, 1], not [4, 3, 2, 1]"),
    (ungroupedOutOfWork, GroupShape.ungrouped, "tab counts [3, 2, 1], not [4, 2, 1]"),
] as [(ProbeState, GroupShape, String)])
func groupStepFailsATabInTheWrongPlace(seen: ProbeState, expected: GroupShape, says: String) {
    #expect(seen.groupPaths == expected.paths, "the paths alone read right")
    #expect(!expected.holds(seen))
    do {
        try expected.check(seen, after: "after")
        Issue.record("R49 passed a tab in the wrong place")
    } catch StepError.fail(let text) {
        #expect(text == "after: \(says)")
    } catch {
        Issue.record("not a FAIL: \(error)")
    }
}

/// Only the levels differ: page 5 at the top level's end, every count and own tab right.
@Test func groupStepReadsTheRowLevels() {
    var seen = state(.ungrouped)
    seen.rowLevels = [0, 0, 1, 1, 1, 2, 2, 0]
    #expect(!GroupShape.ungrouped.holds(seen))
}

@Test(arguments: [GroupShape.built, .renamed, .atTop, .ungrouped, .closed])
func groupStepPassesTheTreeItExpects(shape: GroupShape) throws {
    try shape.check(state(shape), after: "")
    #expect(shape.rows.count == shape.levels.count && shape.paths.count == shape.counts.count)
    #expect(shape.ownTabs.count == shape.paths.count)
}
