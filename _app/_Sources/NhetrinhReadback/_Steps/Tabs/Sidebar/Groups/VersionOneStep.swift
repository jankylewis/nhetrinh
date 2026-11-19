import Foundation
import NhetrinhCore

/// R43 (P7): a session file of version 1, as every build before P7 wrote it (`SessionStore.save`), in the
/// readback profile's folder. The launch shows its tabs; its bytes are kept once as `session.v1.json`;
/// the next save is the version the app writes, `TreeSession.version` (3 since P8-GROUPS-1; NT-GAT-014).
enum VersionOneStep {
    static func run(_ app: AppSession) throws -> String {
        app.quit()
        guard LifecycleSteps.forgetSession(), let folder = folder() else {
            throw StepError.cannotDrive("the readback profile's session could not be reset")
        }
        let pages = try LifecycleSteps.pages()
        let tabs = (1...3).compactMap { page in
            URL(string: pages.url("/page/\(page)")).map {
                SessionTab(url: $0, title: TestPageContent.title(page: page))
            }
        }
        let old = Session(tabs: tabs, selectedIndex: 1, sidebarWidth: 220, collapsed: false, version: 1)
        let file = folder.appendingPathComponent(SessionStore.fileName)
        do { try SessionStore.save(old, in: folder) } catch { throw StepError.cannotDrive("\(error)") }
        let written = try Data(contentsOf: file)
        try app.launch(probe: true)
        let titles = FolderSteps.titles(1...3)
        let state = try FolderSteps.until(app, "the version 1 file's 3 tabs") { $0.rows == titles }
        try expect(state.selected == 1 && state.folders.isEmpty, "selected row \(state.selected.map { $0 + 1 } ?? 0)")
        let backup = folder.appendingPathComponent(TreeSessionStore.backupFileName)
        try expect((try? Data(contentsOf: backup)) == written, "\(TreeSessionStore.backupFileName) is not the v1 file")
        try app.act(.menu(["nhetrinh", "Quit nhetrinh"]), "nhetrinh > Quit nhetrinh")
        try expect(app.waitForEnd(10), "nhetrinh > Quit nhetrinh: the app still runs after 10 s")
        let saved = (try? Data(contentsOf: file)) ?? Data()
        try expect(isCurrentSave(saved, tabs: tabs), "the save at quit is not version \(TreeSession.version)")
        return "a version 1 session.json (3 test pages, row 2 selected): launch shows rows \(state.rows), row 2 "
            + "selected; \(TreeSessionStore.backupFileName) holds the v1 bytes; "
            + "quit saved version \(TreeSession.version)"
    }

    /// The save at quit holds `tabs` and is the version the app writes: `TreeSession.version`, never a literal.
    static func isCurrentSave(_ bytes: Data, tabs: [SessionTab]) -> Bool {
        TreeSessionStore.version(of: bytes) == TreeSession.version
            && TreeSessionStore.decode(bytes)?.tree.allTabs == tabs
    }

    private static func folder() -> URL? {
        AppSession.folder()
    }
}
