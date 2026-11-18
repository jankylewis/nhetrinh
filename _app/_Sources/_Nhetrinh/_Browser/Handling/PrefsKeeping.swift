import AppKit
import NhetrinhCore
import WebKit

/// P4: `prefs.json` next to the session (per profile). Every change from the Settings Hub or a zoom is
/// applied at once and saved at once: the file is small. A measurement run keeps no file.
extension BrowserWindowController {
    func loadPrefs(from folder: URL?) {
        prefsFolder = folder
        if let folder {
            prefs = PrefsStore.load(from: folder) { reason in Log.app.error("prefs: \(reason, privacy: .public)") }
        }
        applyPrefs(old: nil)
    }

    /// Change the prefs, apply what changed, save.
    func updatePrefs(_ change: (inout Prefs) -> Void) {
        let old = prefs
        change(&prefs)
        guard prefs != old else { return }
        applyPrefs(old: old)
        guard let prefsFolder else { return }
        do {
            try PrefsStore.save(prefs, in: prefsFolder)
        } catch {
            Log.app.error("prefs: save failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func applyPrefs(old: Prefs?) {
        if old?.appearance != prefs.appearance { NSApp.appearance = Self.appearance(prefs.appearance) }
        if old?.idleUnloadMinutes != prefs.idleUnloadMinutes, old != nil { startIdleUnloading() }
        if old == nil { startIdleUnloading() }
        hub?.show(prefs)
    }

    /// nil follows macOS (System); pages follow the window through `prefers-color-scheme`.
    static func appearance(_ choice: Appearance) -> NSAppearance? {
        switch choice {
        case .system: return nil
        case .light: return NSAppearance(named: .aqua)
        case .dark: return NSAppearance(named: .darkAqua)
        }
    }

    /// nhetrinh > Settings Hub… (⌘,): the one settings window (D19).
    @objc func showSettingsHub(_ sender: Any?) {
        let hub = self.hub ?? SettingsHub(store: WebConfig.shared.websiteDataStore)
        self.hub = hub
        hub.onChange = { [weak self] change in self?.updatePrefs(change) }
        hub.show(prefs)
        hub.showWindow(nil)
        hub.window?.makeKeyAndOrderFront(nil)
    }
}
