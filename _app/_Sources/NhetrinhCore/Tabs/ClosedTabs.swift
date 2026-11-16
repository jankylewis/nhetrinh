import Foundation

// P2 (hubs/product/plan/M1_DAILY_DRIVER.md). STUB, red first (P2-PREP-1, DECISIONS.md D24):
// the types compile, the behaviour is not built; the tests in ClosedTabsTests.swift fail until P2.

/// A closed tab, kept so File > Reopen Closed Tab can bring it back where it was.
public struct ClosedTab: Equatable, Sendable {
    public let url: URL
    public let title: String
    public let index: Int

    public init(url: URL, title: String, index: Int) {
        self.url = url
        self.title = title
        self.index = index
    }
}

/// The last closed tabs of this run, newest first out. Never saved: a relaunch starts empty.
public struct ClosedTabs: Sendable {
    /// At most this many are kept; pushing one more drops the oldest.
    public static let capacity = 20

    public init() {}

    /// How many tabs can be reopened now.
    public var count: Int {
        0  // STUB
    }

    /// Keeps a tab that was just closed.
    public mutating func push(_ tab: ClosedTab) {
        // STUB
    }

    /// The tab closed last, removed from the list; nil when there is none.
    public mutating func pop() -> ClosedTab? {
        nil  // STUB
    }
}
