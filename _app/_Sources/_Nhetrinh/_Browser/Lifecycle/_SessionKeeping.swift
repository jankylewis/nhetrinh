import AppKit
import NhetrinhCore

/// Session restore (P1): the tabs are saved 2 s after a tab change and at quit, and come back at
/// launch, each unloaded except the selected one. A measurement run (NHT_BENCH_URLS) neither reads
/// nor writes a session; each profile keeps its own in its folder (`ProfileLayout`, P10-PROFILE, D29).
extension BrowserWindowController {
    static let saveDelay: TimeInterval = 2

    /// The folder of this launch's session: the one the launch's migration chose, else the profile's own under
    /// `DataRoot` (a temporary folder before a launch); nil when the session is off (bench seeding, a refused name).
    static func sessionFolder(_ env: [String: String] = ProcessInfo.processInfo.environment) -> URL? {
        guard (env["NHT_BENCH_URLS"] ?? "").isEmpty, let layout = profileLayout(env) else { return nil }
        return DataRoot.inUse ?? layout.folder
    }

    /// Restore the saved session, or one home tab. Turns saving on.
    func openSavedSession(in folder: URL, home: URL) {
        let session = TreeSessionStore.load(from: folder, home: home) { reason in
            Log.app.error("session: \(reason, privacy: .public)")
        }
        sessionFolder = folder
        restore(session)
    }

    /// Show `session`: every tab as a row, in its folder (P7), only the selected one loaded.
    func restore(_ session: TreeSession) {
        tree = session.tree.compactMapTabs { Tab(url: $0.url, title: $0.title) }
        if tabs.isEmpty { tabs = [Tab(url: nil)] }
        sidebarWidth = session.sidebarWidth
        if let side = sideItem {
            side.isCollapsed = session.collapsed
            if !session.collapsed { keepSidebarWidth(session.sidebarWidth) }  // on its side (P8-SIDE-1)
        }
        selected = -1
        select(min(max(0, session.selectedIndex), tabs.count - 1))
    }

    /// A tab changed: save once, `saveDelay` after the first change (later changes join that save).
    func sessionChanged() {
        guard sessionFolder != nil, saveTimer == nil else { return }
        saveTimer = Timer.scheduledTimer(withTimeInterval: Self.saveDelay, repeats: false) { [weak self] _ in
            self?.saveSession()
        }
    }

    /// The session as the window shows it now.
    var currentSession: TreeSession {
        let collapsed = sideItem?.isCollapsed ?? false
        if !collapsed, sidebar.frame.width >= 100 { sidebarWidth = Double(sidebar.frame.width) }
        return TreeSession.capture(tree, selected: selected, sidebarWidth: sidebarWidth, collapsed: collapsed) { tab in
            tab.url.map { SessionTab(url: $0, title: tab.title) }
        }
    }

    /// Save now (the timer, and at quit). A failure is logged; the last good file stays.
    func saveSession() {
        saveTimer?.invalidate()
        saveTimer = nil
        guard let folder = sessionFolder else { return }
        do {
            try TreeSessionStore.save(currentSession, in: folder)
        } catch {
            Log.app.error("session: save failed: \(error.localizedDescription, privacy: .public)")
        }
    }
}
