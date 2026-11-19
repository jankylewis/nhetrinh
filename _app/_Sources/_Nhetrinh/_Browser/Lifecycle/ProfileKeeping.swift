import AppKit
import NhetrinhCore

/// P10-PROFILE (D29): one folder per profile. At launch, before any file is read, P9's files move to the
/// profile's folder (`ProfileMigration`) and `profile.json` is written; Settings Hub > Show data folder and
/// Reset profile…. The logic and its tests are `NhetrinhCore`'s; the seams are `DataRoot`.
extension BrowserWindowController {
    /// This launch's profile; nil for a refused NHT_PROFILE (logged at launch: such a launch keeps nothing).
    static func profileLayout(_ env: [String: String]) -> ProfileLayout? {
        ProfileLayout(applicationSupport: DataRoot.support, profile: env["NHT_PROFILE"])
    }

    /// At launch: the migration, `profile.json`, and the folder this launch uses (nil: none kept); `AppDelegate`
    /// keeps it as `DataRoot.inUse`.
    static func prepareProfile(_ env: [String: String]) -> URL? {
        guard (env["NHT_BENCH_URLS"] ?? "").isEmpty else { return nil }
        guard let layout = profileLayout(env) else {
            let why = ProfileLayout.refusal(env["NHT_PROFILE"] ?? "") ?? "refused"
            Log.app.error("profile: the name is refused (\(why, privacy: .public)); nothing is kept")
            return nil
        }
        let outcome = ProfileMigration.run(layout)
        if outcome.moved + outcome.kept > 0 || outcome.failure != nil {
            Log.app.info("\(outcome.line, privacy: .public)")  // counts only, no path
        }
        if outcome.folder == layout.folder {
            do { try layout.info.write(in: layout.folder) } catch { Log.app.error("profile: profile.json not written") }
        }
        return outcome.folder
    }

    /// Settings Hub > Show data folder: this profile's folder in Finder.
    func showDataFolder() {
        guard let folder = sessionFolder ?? prefsFolder else { return }
        DataRoot.reveal(folder)
    }

    /// Settings Hub > Reset profile…, confirmed: this profile's folder emptied, its Keychain item and its
    /// store's website data removed, then one home tab. Never another profile (`ProfileReset`).
    func resetProfile(env: [String: String] = ProcessInfo.processInfo.environment, home: URL? = homeURL,
                      done: @escaping () -> Void = {}) {
        guard let folder = sessionFolder ?? prefsFolder, let layout = Self.profileLayout(env) else { return done() }
        saveTimer?.invalidate()
        saveTimer = nil
        history.close()  // before its file goes (P11)
        do {
            let gone = try ProfileReset.empty(layout, inUse: folder)
            Log.app.info("profile: reset, \(gone.count, privacy: .public) entries removed")
        } catch {
            Log.app.error("profile: reset refused, the folder in use is not the profile's")
            return done()
        }
        signIns?.forget()
        DataRoot.clearWebData { [weak self] in
            self?.startOver(home: home)
            done()
        }
    }

    /// The defaults and one home tab, saved.
    private func startOver(home: URL?) {
        if tabs.indices.contains(selected) { tabs[selected].webView?.removeFromSuperview() }
        closedTabs = ClosedTabs()
        updatePrefs { $0 = Prefs() }
        if let home { restore(.home(home)) } else { tabs = [Tab(url: nil)]; selected = -1; select(0) }
        saveSession()
    }
}
