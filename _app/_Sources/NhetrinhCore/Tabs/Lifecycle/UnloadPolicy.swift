import Foundation

// P1 (hubs/product/plan/M1_DAILY_DRIVER.md), NT-TAB-001; P6 pressure (M3_V1_RELEASE.md).

/// Which background tabs to unload. A pure function: the app asks WebKit if a tab plays
/// (`requestMediaPlaybackState`) and passes the answer in; a playing tab is never unloaded (NT-TAB-001),
/// at any memory pressure level.
public enum UnloadPolicy {
    /// macOS's memory pressure level (P6), by the name the probe sends.
    public enum Pressure: String, Sendable {
        case normal, warning, critical
    }

    /// At a warning a background tab idle longer than this goes (or the normal limit, when shorter).
    public static let warningLimit: TimeInterval = 60

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

    /// The idle time past which a background tab goes at `pressure`; nil: every background tab goes.
    public static func limit(_ pressure: Pressure, normal: TimeInterval) -> TimeInterval? {
        switch pressure {
        case .normal: return normal
        case .warning: return min(normal, warningLimit)
        case .critical: return nil
        }
    }

    /// The indexes of the tabs to unload now, in ascending order: loaded, not selected, silent,
    /// and idle for longer than the limit of `pressure` (exactly at the limit is not yet idle).
    public static func tabsToUnload(_ tabs: [TabState], selected: Int?, now: Date, idleLimit: TimeInterval,
                                    pressure: Pressure = .normal) -> [Int] {
        let limit = limit(pressure, normal: idleLimit)
        return tabs.indices.filter { index in
            let tab = tabs[index]
            let idle = limit.map { now.timeIntervalSince(tab.lastActive) > $0 } ?? true
            return index != selected && tab.isLoaded && !tab.isPlaying && idle
        }
    }
}
