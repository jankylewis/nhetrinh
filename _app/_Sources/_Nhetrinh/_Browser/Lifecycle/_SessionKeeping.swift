import AppKit
import NhetrinhCore

/// Session restore (P1): the tabs are saved 2 s after a tab change and at quit, and come back at
/// launch, each unloaded except the selected one. A measurement run (NHT_BENCH_URLS) neither reads
/// nor writes a session; with NHT_PROFILE the session is that profile's own (`SessionStore.folder`).
extension BrowserWindowController {
    static let saveDelay: TimeInterval = 2

    /// The folder of this launch's session; nil when the session is off (bench seeding).
    static func sessionFolder(_ env: [String: String] = ProcessInfo.processInfo.environment) -> URL? {
        guard (env["NHT_BENCH_URLS"] ?? "").isEmpty,
              let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        else { return nil }
        return SessionStore.folder(applicationSupport: support, profile: env["NHT_PROFILE"])
    }

    /// Restore the saved session, or one home tab. Turns saving on.
    func openSavedSession(in folder: URL, home: URL) {
        let session = SessionStore.load(from: folder, home: home) { reason in
            Log.app.error("session: \(reason, privacy: .public)")
        }
        sessionFolder = folder
        restore(session)
    }

    /// Show `session`: every tab as a row, only the selected one loaded.
    func restore(_ session: Session) {
        tabs = session.tabs.map { Tab(url: $0.url, title: $0.title) }
        if tabs.isEmpty { tabs = [Tab(url: nil)] }
        sidebarWidth = session.sidebarWidth
        if let side = split.splitViewItems.first {
            side.isCollapsed = session.collapsed
            if !session.collapsed { split.splitView.setPosition(CGFloat(session.sidebarWidth), ofDividerAt: 0) }
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
    var currentSession: Session {
        let collapsed = split.splitViewItems.first?.isCollapsed ?? false
        if !collapsed, sidebar.frame.width >= 100 { sidebarWidth = Double(sidebar.frame.width) }
        return Session.capture(tabs.map { (url: $0.url, title: $0.title) }, selected: selected,
                               sidebarWidth: sidebarWidth, collapsed: collapsed)
    }

    /// Save now (the timer, and at quit). A failure is logged; the last good file stays.
    func saveSession() {
        saveTimer?.invalidate()
        saveTimer = nil
        guard let folder = sessionFolder else { return }
        do {
            try SessionStore.save(currentSession, in: folder)
        } catch {
            Log.app.error("session: save failed: \(error.localizedDescription, privacy: .public)")
        }
    }
}
