import AppKit
import NhetrinhCore
import WebKit

/// What the Settings Hub's controls do, and how the readback probe uses them as a user does.
extension SettingsHub {
    @objc func appearanceChosen() {
        let title = appearance.titleOfSelectedItem
        guard let choice = Appearance.allCases.first(where: { $0.title == title }) else { return }
        onChange? { $0.appearance = choice }
    }

    /// P8-SIDE-1: Left or Right; the sidebar moves at once.
    @objc func sideChosen() {
        let title = position.titleOfSelectedItem
        guard let choice = SidebarSide.allCases.first(where: { $0.title == title }) else { return }
        onChange? { $0.sidebarSide = choice }
    }

    @objc func engineChosen() {
        let title = engine.titleOfSelectedItem
        guard let choice = SearchEngine.allCases.first(where: { $0.title == title }) else { return }
        onChange? { $0.searchEngine = choice }
    }

    /// Whole minutes, at least 1; anything else shows the kept value again.
    @objc func minutesTyped() {
        let text = minutes.stringValue.trimmingCharacters(in: .whitespaces)
        guard let value = Int(text), value >= 1 else { return show(shown) }
        onChange? { $0.idleUnloadMinutes = value }
    }

    /// P9-REMEMBER: on keeps sign-ins across a quit; off deletes the kept ones at once.
    @objc func rememberToggled() {
        let on = remember.state == .on
        onChange? { $0.rememberSignIns = on }
    }

    /// Clear Website Data…: a sheet asks first. Cancel is the default button; nothing is removed without a choice.
    /// The buttons and what each removes: `ClearRange` (unit tested: R30 cannot tell them apart, F1).
    @objc func askToClear() {
        guard let window else { return }
        let alert = NSAlert()
        alert.messageText = "Clear website data?"
        alert.informativeText = "Cookies, caches and site storage are removed for every site."
        for title in ClearRange.buttons { alert.addButton(withTitle: title) }
        alert.buttons.last?.hasDestructiveAction = true
        Screen.presenter.begin(alert, on: window) { [weak self] response in
            let first = NSApplication.ModalResponse.alertFirstButtonReturn.rawValue
            if let range = ClearRange(button: response.rawValue - first) { self?.clear(range) }
        }
    }

    /// One of the sheet's ranges: the website data since its date, and with Clear All the per-site settings and
    /// the kept sign-ins (P9-REMEMBER).
    func clear(_ range: ClearRange) {
        removeData(since: range.since(now: Date()))
        guard range.forgetsSiteSettings else { return }
        onChange? { $0.forgetSites() }
        onForgetSignIns?()
    }

    private func removeData(since date: Date) {
        store.removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(), modifiedSince: date) {
            Log.app.info("website data cleared")
        }
    }

    /// The probe's `setting`: the control named `name` set to `value` as a user picks or types it.
    func set(_ name: String, to value: String) -> Bool {
        switch name {
        case "Appearance", "Search engine", Self.positionTitle:
            let popup = name == "Appearance" ? appearance : name == "Search engine" ? engine : position
            guard popup.item(withTitle: value) != nil else { return false }
            popup.selectItem(withTitle: value)
            return popup.sendAction(popup.action, to: popup.target)
        case "Unload idle tabs after":
            minutes.stringValue = value
            return minutes.sendAction(minutes.action, to: minutes.target)
        case Self.rememberTitle:  // "on" or "off", as a click sets the box
            guard value == "on" || value == "off" else { return false }
            remember.state = value == "on" ? .on : .off
            return remember.sendAction(remember.action, to: remember.target)
        default: return false
        }
    }

    /// The probe's `button`: Clear Website Data…, as a click does.
    func press(_ label: String) -> Bool {
        guard label == Self.clearTitle, let window, Screen.presenter.isShown(window) else { return false }
        clear.performClick(nil)
        return true
    }
}
