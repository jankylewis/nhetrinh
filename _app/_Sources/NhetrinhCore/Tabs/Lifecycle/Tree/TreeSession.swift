import Foundation

// P7 session schema version 2 (hubs/product/plan/M3_V1_RELEASE.md). STUB (P7-PREP-1, DECISIONS.md D24):
// nothing is read, written or migrated yet, so the tests in Tests/_NhetrinhCoreTests/Tabs/Lifecycle/Tree/
// are red until P7-BUILD-1. The app still reads and writes version 1 through `SessionStore`.

/// What survives a quit from P7 on: the tab tree, the selected tab, the sidebar.
public struct TreeSession: Equatable, Sendable {
    public static let version = 2

    public var tree: TabTree
    /// The selected tab's path; a root tab has `tab` nil.
    public var selected: TabPath
    public var sidebarWidth: Double
    public var collapsed: Bool

    public init(tree: TabTree, selected: TabPath, sidebarWidth: Double, collapsed: Bool) {
        self.tree = tree
        self.selected = selected
        self.sidebarWidth = sidebarWidth
        self.collapsed = collapsed
    }

    /// One home tab at the root, selected.
    public static func home(_ url: URL) -> TreeSession {
        TreeSession(tree: TabTree(), selected: TabPath(item: 0), sidebarWidth: Session.defaultSidebarWidth,
                    collapsed: false)
    }

    /// A version 1 session: its flat list becomes root tabs, in order; selection and sidebar kept.
    public init(migrating session: Session) {
        self.init(tree: TabTree(), selected: TabPath(item: 0), sidebarWidth: 0, collapsed: false)
    }
}

/// Reads and writes `session.json` as version 2. A version 1 file is migrated, and its bytes are kept
/// once as `session.v1.json`. A bad file (corrupt, newer, a folder inside a folder) is kept as
/// `session.bad.json`, as `SessionStore` does: the app then starts with one home tab.
public enum TreeSessionStore {
    public static let backupFileName = "session.v1.json"

    /// Version 2 JSON, keys sorted.
    public static func encode(_ session: TreeSession) throws -> Data { Data() }

    /// A version 1 file (migrated) or a version 2 file; nil for anything else.
    public static func decode(_ bytes: Data) -> TreeSession? { nil }

    /// Atomic, as `SessionStore.save`.
    public static func save(_ session: TreeSession, in folder: URL) throws {}

    /// The saved session, migrated when it is version 1; `TreeSession.home(home)` when there is none,
    /// it has no tab, or it is bad. `report` hears why a file was not used.
    public static func load(from folder: URL, home: URL, report: (String) -> Void = { _ in }) -> TreeSession {
        .home(home)
    }
}
