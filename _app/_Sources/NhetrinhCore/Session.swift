import Foundation

// P1 (hubs/product/plan/M1_DAILY_DRIVER.md). STUB, red first (P1-PREP-1, DECISIONS.md D22):
// the types compile, the behaviour is not built; the tests in SessionTests.swift fail until P1.

/// One tab as it is saved: where it was, and what it was called.
public struct SessionTab: Codable, Equatable, Sendable {
    public var url: URL
    public var title: String

    public init(url: URL, title: String) {
        self.url = url
        self.title = title
    }
}

/// What survives a quit: the tabs, the selected one, the sidebar.
public struct Session: Codable, Equatable, Sendable {
    /// The only version this build reads. A newer one is kept aside, never read half.
    public static let currentVersion = 1

    public var version: Int
    public var tabs: [SessionTab]
    public var selectedIndex: Int
    public var sidebarWidth: Double
    public var collapsed: Bool

    public init(tabs: [SessionTab], selectedIndex: Int, sidebarWidth: Double, collapsed: Bool,
                version: Int = Session.currentVersion) {
        self.version = version
        self.tabs = tabs
        self.selectedIndex = selectedIndex
        self.sidebarWidth = sidebarWidth
        self.collapsed = collapsed
    }

    /// The default sidebar width of a new session, in points.
    public static let defaultSidebarWidth = 220.0

    /// One home tab, selected: what the app starts with when there is nothing good to restore.
    public static func home(_ url: URL) -> Session {
        Session(tabs: [], selectedIndex: 0, sidebarWidth: defaultSidebarWidth, collapsed: false)  // STUB
    }
}

/// Reads and writes `session.json` in a folder (the app passes ~/Library/Application Support/nhetrinh).
/// A file that cannot be read (corrupt, or from a newer version) is renamed `session.bad.json`,
/// and the app starts with one home tab: no crash, no silent loss.
public enum SessionStore {
    public static let fileName = "session.json"
    public static let badFileName = "session.bad.json"

    /// Atomic: the folder holds the old file or the new one, never half of one.
    public static func save(_ session: Session, in folder: URL) throws {}  // STUB

    /// The saved session; `Session.home(home)` when there is none, it is empty, or it is bad.
    public static func load(from folder: URL, home: URL) -> Session {
        Session(tabs: [], selectedIndex: 0, sidebarWidth: 0, collapsed: false)  // STUB
    }
}
