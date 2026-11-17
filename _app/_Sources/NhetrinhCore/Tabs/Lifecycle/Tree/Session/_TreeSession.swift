import Foundation

// P7 session schema version 2 (hubs/product/plan/M3_V1_RELEASE.md), version 3 since P8-GROUPS-1 (nested
// groups). `Session` stays the version 1 file: read only, to migrate it. The file shapes are fixed by the
// tests' SessionFixtures.swift. Version 3: {"items":[{"tab":{…}} | {"folder":{"name","collapsed","items"}}],
// "selected":[…], …}; version 2 (read only): a folder's "tabs" hold tabs, "selected" is {"item","tab"}.

/// What survives a quit from P7 on: the tab tree, the selected tab, the sidebar.
public struct TreeSession: Equatable, Sendable {
    public static let version = 3

    public var tree: TabTree
    /// The selected tab's path.
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
        TreeSession(migrating: Session.home(url))
    }

    /// A version 1 session: its flat list becomes root tabs, in order; selection (clamped) and sidebar kept.
    public init(migrating session: Session) {
        let tree = TabTree(tabs: session.tabs)
        let selected = tree.path(ofFlat: session.clamped.selectedIndex) ?? TabPath(item: 0)
        self.init(tree: tree, selected: selected, sidebarWidth: session.sidebarWidth, collapsed: session.collapsed)
    }

    /// The session of the app's tree as it is. A tab with no address yet (a new, empty tab) is not saved;
    /// the selection moves to the nearest saved tab before it. Folders are kept, even empty.
    public static func capture<Tab>(_ tree: Tree<Tab>, selected: Int, sidebarWidth: Double, collapsed: Bool,
                                    saved: (Tab) -> SessionTab?) -> TreeSession {
        let kept = tree.compactMapTabs(saved)
        let before = tree.allTabs.prefix(max(0, selected + 1)).compactMap(saved).count
        let path = kept.path(ofFlat: max(0, before - 1)) ?? TabPath(item: 0)
        return TreeSession(tree: kept, selected: path, sidebarWidth: sidebarWidth, collapsed: collapsed)
    }

    /// The flat index of the selected tab; the first tab when the path names none (a hand-edited file).
    public var selectedIndex: Int { tree.flatIndex(of: selected) ?? 0 }
}

/// Reads and writes `session.json` as version 3. A version 2 file is read as it is; a version 1 file is
/// migrated, and its bytes are kept once as `session.v1.json`. A bad file (corrupt, newer, a version 2
/// folder inside a folder, groups deeper than `GroupDepth.max`) is kept as `session.bad.json`, as
/// `SessionStore` does: the app then starts with one home tab.
public enum TreeSessionStore {
    public static let backupFileName = "session.v1.json"

    private struct File: Codable {
        let version: Int
        let items: [TabTree.Item]
        let selected: TabPath
        let sidebarWidth: Double
        let collapsed: Bool
    }

    /// Version 3 JSON, keys sorted.
    public static func encode(_ session: TreeSession) throws -> Data {
        let file = File(version: TreeSession.version, items: session.tree.items, selected: session.selected,
                        sidebarWidth: session.sidebarWidth, collapsed: session.collapsed)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(file)
    }

    /// A version 1 file (migrated), a version 2 file (one level) or a version 3 file; nil for anything else.
    public static func decode(_ bytes: Data) -> TreeSession? {
        let version = version(of: bytes)
        if version == 1 { return SessionStore.decode(bytes).map { TreeSession(migrating: $0) } }
        guard version == 2 || version == TreeSession.version,
              let file = try? JSONDecoder().decode(File.self, from: bytes) else { return nil }
        let tree = TabTree(items: file.items)
        guard tree.depth <= (version == 2 ? 1 : GroupDepth.max) else { return nil }
        return TreeSession(tree: tree, selected: file.selected, sidebarWidth: file.sidebarWidth,
                           collapsed: file.collapsed)
    }

    /// Atomic, as `SessionStore.save`.
    public static func save(_ session: TreeSession, in folder: URL) throws {
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        try encode(session).write(to: folder.appendingPathComponent(SessionStore.fileName), options: .atomic)
    }

    /// The saved session, migrated when it is version 1; `TreeSession.home(home)` when there is none,
    /// it has no tab, or it is bad. `report` hears why a file was not used.
    public static func load(from folder: URL, home: URL, report: (String) -> Void = { _ in }) -> TreeSession {
        let file = folder.appendingPathComponent(SessionStore.fileName)
        guard let bytes = try? Data(contentsOf: file) else { return .home(home) }
        guard var session = decode(bytes) else {
            report(SessionStore.keepBad(file, in: folder))
            return .home(home)
        }
        if version(of: bytes) == 1 { report(keepOnce(bytes, in: folder)) }
        guard !session.tree.allTabs.isEmpty else { return session.withHomeTab(home) }
        session.selected = session.tree.path(ofFlat: session.selectedIndex) ?? TabPath(item: 0)
        return session
    }

    /// The version 1 bytes as `session.v1.json`, unless a backup is already there: kept once.
    private static func keepOnce(_ bytes: Data, in folder: URL) -> String {
        let backup = folder.appendingPathComponent(backupFileName)
        guard !FileManager.default.fileExists(atPath: backup.path) else {
            return "version 1 \(SessionStore.fileName) migrated; \(backupFileName) already kept"
        }
        do {
            try bytes.write(to: backup, options: .atomic)
            return "version 1 \(SessionStore.fileName) migrated; kept as \(backupFileName)"
        } catch {
            return "version 1 \(SessionStore.fileName) migrated; keeping \(backupFileName) failed: \(error)"
        }
    }

    /// The `version` a session file says it is; nil when it says none.
    public static func version(of bytes: Data) -> Int? {
        struct Head: Decodable { let version: Int }
        return (try? JSONDecoder().decode(Head.self, from: bytes))?.version
    }
}
