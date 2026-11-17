import Foundation
import NhetrinhCore

/// R43 (P7): a session file of version 1, as every build before P7 wrote it (`SessionStore.save`), in the
/// readback profile's folder. The launch shows its tabs; its bytes are kept once as `session.v1.json`;
/// the next save is version 2.
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
        let saved = (try? Data(contentsOf: file)).flatMap(TreeSessionStore.decode)
        let text = String(decoding: (try? Data(contentsOf: file)) ?? Data(), as: UTF8.self)
        try expect(saved?.tree.allTabs == tabs && text.contains("\"version\":2"), "the save at quit is not version 2")
        return "a version 1 session.json (3 test pages, row 2 selected): launch shows rows \(state.rows), row 2 "
            + "selected; \(TreeSessionStore.backupFileName) holds the v1 bytes; quit saved version 2"
    }

    private static func folder() -> URL? {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first.map {
            SessionStore.folder(applicationSupport: $0, profile: AppSession.profile)
        }
    }
}
