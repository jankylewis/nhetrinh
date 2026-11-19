import AppKit
import NhetrinhCore

/// P10-PROFILE (D29): the hub's Profile row: the profile's name, Show data folder, Reset profile….
extension SettingsHub {
    /// The name of the launch's profile (`Default` without NHT_PROFILE).
    func show(profile name: String) {
        profileName.stringValue = name
    }

    @objc func showFolderPressed() {
        onShowFolder?()
    }

    /// Reset profile…: a sheet asks first; Cancel is the default button, Reset is marked destructive.
    @objc func askToReset() {
        guard let window else { return }
        let alert = NSAlert()
        alert.messageText = "Reset profile \u{201C}\(profileName.stringValue)\u{201D}?"
        alert.informativeText = "Its tabs, settings, cookies, site data and kept sign-ins are removed, "
            + "and it starts again with one home tab. Other profiles are not touched."
        for title in Self.resetButtons { alert.addButton(withTitle: title) }
        alert.buttons.last?.hasDestructiveAction = true
        Screen.presenter.begin(alert, on: window) { [weak self] response in
            if Self.resets(response) { self?.onResetProfile?() }
        }
    }

    /// The sheet's buttons, in order: Cancel first (the default, Return), then Reset.
    static let resetButtons = ["Cancel", "Reset"]

    /// Only the Reset button resets; Cancel, Escape and anything else do nothing.
    static func resets(_ response: NSApplication.ModalResponse) -> Bool {
        let first = NSApplication.ModalResponse.alertFirstButtonReturn.rawValue
        return response.rawValue - first == resetButtons.firstIndex(of: "Reset")
    }
}
