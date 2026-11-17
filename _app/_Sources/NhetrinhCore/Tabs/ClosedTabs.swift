import Foundation

// P2 (hubs/product/plan/M1_DAILY_DRIVER.md); a closed group since P8-GROUPS-1. Tests in ClosedTabsTests.swift.

/// A closed tab, kept so File > Reopen Closed Tab can bring it back where it was.
public struct ClosedTab: Equatable, Sendable {
    public let url: URL
    public let title: String
    public let index: Int
    /// P7: where it was in the tree, and the names of the groups along that path, top first (none: a root
    /// tab), for `Tree.reinsert`.
    public let path: TabPath?
    public let groups: [String]

    public init(url: URL, title: String, index: Int, path: TabPath? = nil, groups: [String] = []) {
        self.url = url
        self.title = title
        self.index = index
        self.path = path
        self.groups = groups
    }
}

/// A group closed with all its tabs (Close Group…, P8-GROUPS-1): reopened as one, back where it was; the
/// groups along its path are made again when they are gone.
public struct ClosedGroup: Equatable, Sendable {
    public let group: TabFolder
    public let path: TabPath
    public let groups: [String]

    public init(group: TabFolder, path: TabPath, groups: [String]) {
        self.group = group
        self.path = path
        self.groups = groups
    }
}

/// What Reopen Closed Tab brings back: a tab, or a whole group.
public enum Closed: Equatable, Sendable {
    case tab(ClosedTab)
    case group(ClosedGroup)
}

/// The last closed tabs and groups of this run, newest first out. Never saved: a relaunch starts empty.
public struct ClosedTabs: Sendable {
    /// At most this many are kept; pushing one more drops the oldest.
    public static let capacity = 20

    private var closed: [Closed] = []

    public init() {}

    /// How many can be reopened now.
    public var count: Int {
        closed.count
    }

    /// Keeps a tab that was just closed.
    public mutating func push(_ tab: ClosedTab) {
        push(.tab(tab))
    }

    /// Keeps a tab or a group that was just closed.
    public mutating func push(_ item: Closed) {
        closed.append(item)
        if closed.count > Self.capacity { closed.removeFirst(closed.count - Self.capacity) }
    }

    /// The tab or group closed last, removed from the list; nil when there is none.
    public mutating func pop() -> Closed? {
        closed.popLast()
    }
}
