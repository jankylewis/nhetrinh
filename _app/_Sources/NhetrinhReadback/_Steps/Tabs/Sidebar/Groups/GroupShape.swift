import Foundation
import NhetrinhCore

/// What R49 reads at each stage: the group paths, each group's tab count at any depth, each group's own
/// tabs (test pages), the rows and their levels. Paths and the tab order alone can pass falsely
/// (REVIEW_P8_GROUPS, defect 1): page 5 is last in the tab order wherever it lands, so a reopen that put it
/// at the top level's end, beside an empty group, read the same. Counts, own tabs and levels tell it.
struct GroupShape: Equatable, Sendable {
    var paths: [String]
    var counts: [Int]
    var ownTabs: [[Int]]
    var rows: [String]
    var levels: [Int]

    /// FAIL naming the first field that differs from this shape.
    func check(_ state: ProbeState, after what: String) throws {
        let tabs = ownTabs.map { $0.map(GroupDriving.page) }
        try expect(state.groupPaths == paths, "\(what): groups \(state.groupPaths), not \(paths)")
        try expect(state.groupCounts == counts, "\(what): tab counts \(state.groupCounts), not \(counts)")
        try expect(state.folderTabs == tabs, "\(what): the groups' own tabs \(state.folderTabs), not \(tabs)")
        try expect(state.rows == rows && state.rowLevels == levels,
                   "\(what): rows \(state.rows) at levels \(state.rowLevels), not \(rows) at \(levels)")
    }

    func holds(_ state: ProbeState) -> Bool { (try? check(state, after: "")) != nil }

    private static func page(_ page: Int) -> String { GroupDriving.page(page) }

    /// MBing > FE > PRs > Feedback entry, a tab at each level.
    static let built = GroupShape(
        paths: ["MBing", "MBing > FE", "MBing > FE > PRs", "MBing > FE > PRs > Feedback entry"],
        counts: [4, 3, 2, 1], ownTabs: [[2], [3], [4], [5]],
        rows: [page(1), "MBing", page(2), "FE", page(3), "PRs", page(4), "Feedback entry", page(5)],
        levels: [0, 0, 1, 1, 2, 2, 3, 3, 4])

    /// PRs renamed Pull requests; also the tree after it moved to the top level and back.
    static let renamed = GroupShape(
        paths: ["MBing", "MBing > FE", "MBing > FE > Pull requests", "MBing > FE > Pull requests > Feedback entry"],
        counts: [4, 3, 2, 1], ownTabs: [[2], [3], [4], [5]],
        rows: [page(1), "MBing", page(2), "FE", page(3), "Pull requests", page(4), "Feedback entry", page(5)],
        levels: [0, 0, 1, 1, 2, 2, 3, 3, 4])

    /// Pull requests moved to the top level, with all inside, after MBing.
    static let atTop = GroupShape(
        paths: ["MBing", "MBing > FE", "Pull requests", "Pull requests > Feedback entry"],
        counts: [2, 1, 2, 1], ownTabs: [[2], [3], [4], [5]],
        rows: [page(1), "MBing", page(2), "FE", page(3), "Pull requests", page(4), "Feedback entry", page(5)],
        levels: [0, 0, 1, 1, 2, 0, 1, 1, 2])

    /// FE ungrouped: its tab and Pull requests move up into MBing, in place. Also the tree after the reopen.
    static let ungrouped = GroupShape(
        paths: ["MBing", "MBing > Pull requests", "MBing > Pull requests > Feedback entry"],
        counts: [4, 2, 1], ownTabs: [[2, 3], [4], [5]],
        rows: [page(1), "MBing", page(2), page(3), "Pull requests", page(4), "Feedback entry", page(5)],
        levels: [0, 0, 1, 1, 1, 2, 2, 3])

    /// Feedback entry closed with its tab.
    static let closed = GroupShape(
        paths: ["MBing", "MBing > Pull requests"], counts: [3, 1], ownTabs: [[2, 3], [4]],
        rows: [page(1), "MBing", page(2), page(3), "Pull requests", page(4)], levels: [0, 0, 1, 1, 1, 2])
}
