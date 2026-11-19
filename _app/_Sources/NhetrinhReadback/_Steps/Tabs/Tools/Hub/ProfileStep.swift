import Foundation
import NhetrinhCore

/// R53 (P10-PROFILE, D29): one folder per profile, as a user meets it. In the profile readback: three tabs, Quit;
/// its own folder `nhetrinh/readback/` holds `session.json` and a `profile.json` naming readback with its own
/// store and Keychain service, and no crash marker (the quit was clean); a launch gives back the same rows.
/// Only that folder is read (`AppSession.folder()`): never `Default`, the headmate's.
enum ProfileStep {
    static let step = Step(id: "R53", name: "the readback profile keeps its files in its own folder; a relaunch "
        + "keeps the tabs", run: run)

    static func run(_ app: AppSession) throws -> String {
        guard let folder = AppSession.folder(), isReadbacks(folder) else {
            throw StepError.cannotDrive("the readback profile's folder could not be found")
        }
        try LifecycleSteps.freshStart(app)
        try LifecycleSteps.openThree(app)
        let before = try app.state()
        try app.act(.menu(["nhetrinh", "Quit nhetrinh"]), "nhetrinh > Quit nhetrinh")
        try expect(app.waitForEnd(10), "nhetrinh > Quit nhetrinh: the app still runs after 10 s")
        let names = Set((try? FileManager.default.contentsOfDirectory(atPath: folder.path)) ?? [])
        if let failure = failure(names: names, info: ProfileInfo.read(from: folder)) { throw StepError.fail(failure) }
        try app.launch(probe: true)
        let after = try LifecycleSteps.restored(app, rows: before.rows.count)
        try expect(after.rows == before.rows, "after the launch the rows are \(after.rows), not \(before.rows)")
        return "3 tabs, Quit: nhetrinh/readback/ holds \(names.sorted().joined(separator: ", ")); profile.json "
            + "names readback, its own store and service; no crash marker; launch: the same \(after.rows.count) rows"
    }

    /// The readback profile's folder, never Default's.
    static func isReadbacks(_ folder: URL) -> Bool {
        folder.lastPathComponent == AppSession.profile && folder.lastPathComponent != ProfileLayout.defaultName
    }

    /// What `profile.json` must say for readback (the root does not change it).
    static var expectedInfo: ProfileInfo? {
        ProfileLayout(applicationSupport: URL(fileURLWithPath: "/"), profile: AppSession.profile)?.info
    }

    /// Why the folder after a clean quit is wrong, or nil.
    static func failure(names: Set<String>, info: ProfileInfo?) -> String? {
        let missing = [SessionStore.fileName, ProfileInfo.fileName].filter { !names.contains($0) }
        if !missing.isEmpty { return "after Quit nhetrinh/readback/ lacks \(missing.joined(separator: ", "))" }
        if names.contains(CleanQuitMarker.fileName) { return "after Quit the crash marker is still there" }
        guard let info, info == expectedInfo else {
            return "profile.json is \(info.map { "\($0.name), store \($0.webStore)" } ?? "unreadable"), not readback's"
        }
        return nil
    }
}

/// P10-PROFILE (D29): where the readback profile keeps its files.
extension AppSession {
    /// The readback profile's own folder (`nhetrinh/readback/`, D29): never `Default`'s.
    static func folder(support: URL? = FileManager.default.urls(for: .applicationSupportDirectory,
                                                                in: .userDomainMask).first) -> URL? {
        support.flatMap { ProfileLayout(applicationSupport: $0, profile: profile)?.folder }
    }

    /// Its folder and P9's old one (`profiles/<identifier>/`, moved in at the app's next launch): a reset clears
    /// both, so an old session never comes back on the first run after an update. Never `Default`'s.
    static func folders(support: URL? = FileManager.default.urls(for: .applicationSupportDirectory,
                                                                 in: .userDomainMask).first) -> [URL] {
        guard let support, let layout = ProfileLayout(applicationSupport: support, profile: profile) else { return [] }
        return [layout.folder, layout.legacyFolder]
    }
}
