import Foundation

// P1 (hubs/product/plan/M1_DAILY_DRIVER.md). STUB, red first (P1-PREP-1, DECISIONS.md D22):
// the types compile, the behaviour is not built; the tests in UnloadPolicyTests.swift fail until P1.

/// Which background tabs to unload. A pure function: the app asks WebKit if a tab plays
/// (`requestMediaPlaybackState`) and passes the answer in; a playing tab is never unloaded (NT-TAB-001).
public enum UnloadPolicy {
    /// What the policy needs to know about one tab.
    public struct TabState: Equatable, Sendable {
        public let lastActive: Date
        public let isLoaded: Bool
        public let isPlaying: Bool

        public init(lastActive: Date, isLoaded: Bool, isPlaying: Bool) {
            self.lastActive = lastActive
            self.isLoaded = isLoaded
            self.isPlaying = isPlaying
        }
    }

    /// The indexes of the tabs to unload now, in ascending order.
    public static func tabsToUnload(_ tabs: [TabState], selected: Int?, now: Date, idleLimit: TimeInterval) -> [Int] {
        []  // STUB
    }
}
