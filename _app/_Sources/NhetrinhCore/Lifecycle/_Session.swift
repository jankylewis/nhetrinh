import Foundation

// P1 (hubs/product/plan/M1_DAILY_DRIVER.md): what survives a quit. Read and written by SessionStore.

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
        Session(tabs: [SessionTab(url: url, title: url.host ?? url.absoluteString)], selectedIndex: 0,
                sidebarWidth: defaultSidebarWidth, collapsed: false)
    }

    /// The session of the app's tabs as they are. A tab with no address yet (a new, empty tab) is
    /// not saved; the selection moves to the nearest saved tab before it.
    public static func capture(_ tabs: [(url: URL?, title: String)], selected: Int, sidebarWidth: Double,
                               collapsed: Bool) -> Session {
        var kept: [SessionTab] = []
        var keptSelected = 0
        for (index, tab) in tabs.enumerated() {
            if let url = tab.url { kept.append(SessionTab(url: url, title: tab.title)) }
            if index == selected { keptSelected = max(0, kept.count - 1) }
        }
        return Session(tabs: kept, selectedIndex: keptSelected, sidebarWidth: sidebarWidth, collapsed: collapsed)
    }

    /// The selected index inside the tabs (a hand-edited file may point past them).
    var clamped: Session {
        var session = self
        session.selectedIndex = min(max(0, selectedIndex), max(0, tabs.count - 1))
        return session
    }
}
