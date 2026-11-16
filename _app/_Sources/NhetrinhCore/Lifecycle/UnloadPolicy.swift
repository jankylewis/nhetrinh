import Foundation

// P1 (hubs/product/plan/M1_DAILY_DRIVER.md), NT-TAB-001.

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

    /// The indexes of the tabs to unload now, in ascending order: loaded, not selected, silent,
    /// and idle for longer than `idleLimit` (exactly at the limit is not yet idle).
    public static func tabsToUnload(_ tabs: [TabState], selected: Int?, now: Date, idleLimit: TimeInterval) -> [Int] {
        tabs.indices.filter { index in
            let tab = tabs[index]
            let idle = now.timeIntervalSince(tab.lastActive) > idleLimit
            return index != selected && tab.isLoaded && !tab.isPlaying && idle
        }
    }
}
