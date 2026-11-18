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

    /// Clear Website Data…: a sheet asks first. Cancel is the default button; nothing is removed without a choice.
    @objc func askToClear() {
        guard let window else { return }
        let alert = NSAlert()
        alert.messageText = "Clear website data?"
        alert.informativeText = "Cookies, caches and site storage are removed for every site."
        alert.addButton(withTitle: "Cancel")
        alert.addButton(withTitle: "Clear Last Hour")
        alert.addButton(withTitle: "Clear All").hasDestructiveAction = true
        alert.beginSheetModal(for: window) { [weak self] response in
            switch response {
            case .alertSecondButtonReturn: self?.removeData(since: Date().addingTimeInterval(-3600))
            case .alertThirdButtonReturn: self?.removeData(since: .distantPast)
            default: break
            }
        }
    }

    private func removeData(since date: Date) {
        store.removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(), modifiedSince: date) {
            Log.app.info("website data cleared")
        }
    }

    /// The probe's `setting`: the control named `name` set to `value` as a user picks or types it.
    func set(_ name: String, to value: String) -> Bool {
        switch name {
        case "Appearance", "Search engine":
            let popup = name == "Appearance" ? appearance : engine
            guard popup.item(withTitle: value) != nil else { return false }
            popup.selectItem(withTitle: value)
            return popup.sendAction(popup.action, to: popup.target)
        case "Unload idle tabs after":
            minutes.stringValue = value
            return minutes.sendAction(minutes.action, to: minutes.target)
        default: return false
        }
    }

    /// The probe's `button`: Clear Website Data…, as a click does.
    func press(_ label: String) -> Bool {
        guard label == Self.clearTitle, window?.isVisible == true else { return false }
        clear.performClick(nil)
        return true
    }
}
