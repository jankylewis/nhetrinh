import Foundation

// P1 (hubs/product/plan/M1_DAILY_DRIVER.md), NT-TAB-001; P6 pressure (M3_V1_RELEASE.md).

/// Which background tabs to unload. A pure function: the app asks WebKit if a tab plays
/// (`requestMediaPlaybackState`) and passes the answer in; a playing tab is never unloaded (NT-TAB-001),
/// nor one holding the camera or the microphone (F3 ruling), at any memory pressure level.
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
        /// The page holds the camera or the microphone (on or muted): kept like a playing tab (F3 ruling).
        public let isCapturing: Bool

        public init(lastActive: Date, isLoaded: Bool, isPlaying: Bool, isCapturing: Bool = false) {
            self.lastActive = lastActive
            self.isLoaded = isLoaded
            self.isPlaying = isPlaying
            self.isCapturing = isCapturing
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

    /// The indexes of the tabs to unload now, in ascending order: loaded, not selected, silent, not capturing,
    /// and idle for longer than the limit of `pressure` (exactly at the limit is not yet idle).
    public static func tabsToUnload(_ tabs: [TabState], selected: Int?, now: Date, idleLimit: TimeInterval,
                                    pressure: Pressure = .normal) -> [Int] {
        let limit = limit(pressure, normal: idleLimit)
        return tabs.indices.filter { index in
            let tab = tabs[index]
            let idle = limit.map { now.timeIntervalSince(tab.lastActive) > $0 } ?? true
            return index != selected && tab.isLoaded && !tab.isPlaying && !tab.isCapturing && idle
        }
    }

    /// Put Tab to Idle / Put Other Tabs to Idle (headmate, 2026-11-19): `chosen` alone, or every tab but `chosen`;
    /// idle time does not count. Only loaded tabs that neither play nor capture (NT-TAB-001, F3 ruling).
    public static func tabsToIdle(_ tabs: [TabState], chosen: Int, others: Bool) -> [Int] {
        tabs.indices.filter { index in
            let tab = tabs[index]
            return (others ? index != chosen : index == chosen) && tab.isLoaded && !tab.isPlaying && !tab.isCapturing
        }
    }
}
