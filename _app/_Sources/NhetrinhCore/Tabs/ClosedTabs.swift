import Foundation

// P2 (hubs/product/plan/M1_DAILY_DRIVER.md); tests in ClosedTabsTests.swift.

/// A closed tab, kept so File > Reopen Closed Tab can bring it back where it was.
public struct ClosedTab: Equatable, Sendable {
    public let url: URL
    public let title: String
    public let index: Int
    /// P7: where it was in the tree, and the name of its folder (nil: a root tab), for `Tree.reinsert`.
    public let path: TabPath?
    public let folder: String?

    public init(url: URL, title: String, index: Int, path: TabPath? = nil, folder: String? = nil) {
        self.url = url
        self.title = title
        self.index = index
        self.path = path
        self.folder = folder
    }
}

/// The last closed tabs of this run, newest first out. Never saved: a relaunch starts empty.
public struct ClosedTabs: Sendable {
    /// At most this many are kept; pushing one more drops the oldest.
    public static let capacity = 20

    private var tabs: [ClosedTab] = []

    public init() {}

    /// How many tabs can be reopened now.
    public var count: Int {
        tabs.count
    }

    /// Keeps a tab that was just closed.
    public mutating func push(_ tab: ClosedTab) {
        tabs.append(tab)
        if tabs.count > Self.capacity { tabs.removeFirst(tabs.count - Self.capacity) }
    }

    /// The tab closed last, removed from the list; nil when there is none.
    public mutating func pop() -> ClosedTab? {
        tabs.popLast()
    }
}
