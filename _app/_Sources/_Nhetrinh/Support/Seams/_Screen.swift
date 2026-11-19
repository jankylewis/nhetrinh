import AppKit

/// P8-TESTWIN-1 (NT-LES lesson in hubs): how the app's windows and sheets come on screen. A sheet begun on
/// a window that is not on screen brings that window on screen, so a unit test that asked a question showed
/// the browser window on the headmate's screen. The launched app shows them with AppKit (`AppDelegate` sets
/// `Screen.presenter` first thing at launch); before a launch, which is every unit test, nothing comes on
/// screen: a window or sheet is only held, read as shown, and a sheet's button answers it as AppKit would.
@MainActor
protocol Presenter: AnyObject {
    func show(_ controller: NSWindowController)
    func isShown(_ window: NSWindow) -> Bool
    func begin(_ alert: NSAlert, on window: NSWindow, done: @escaping (NSApplication.ModalResponse) -> Void)
    func begin(_ panel: NSSavePanel, on window: NSWindow, done: @escaping (NSApplication.ModalResponse) -> Void)
    /// Ends `sheet` with `code`; a panel is cancelled, as its own Cancel does.
    func end(_ sheet: NSWindow, on window: NSWindow, _ code: NSApplication.ModalResponse)
    /// The sheet shown on `window` (the first, when more wait).
    func sheet(on window: NSWindow) -> NSWindow?
}

@MainActor
enum Screen {
    static var presenter: Presenter = HeldScreen()
}

/// The launched app: AppKit's own windows and sheets, as before P8-TESTWIN-1.
@MainActor
final class AppKitScreen: Presenter {
    func show(_ controller: NSWindowController) {
        controller.showWindow(nil)
        controller.window?.makeKeyAndOrderFront(nil)
    }

    func isShown(_ window: NSWindow) -> Bool { window.isVisible }

    func begin(_ alert: NSAlert, on window: NSWindow, done: @escaping (NSApplication.ModalResponse) -> Void) {
        alert.beginSheetModal(for: window, completionHandler: done)
    }

    func begin(_ panel: NSSavePanel, on window: NSWindow, done: @escaping (NSApplication.ModalResponse) -> Void) {
        panel.beginSheetModal(for: window, completionHandler: done)
    }

    func end(_ sheet: NSWindow, on window: NSWindow, _ code: NSApplication.ModalResponse) {
        if let panel = sheet as? NSSavePanel { panel.cancel(nil) } else { window.endSheet(sheet, returnCode: code) }
    }

    func sheet(on window: NSWindow) -> NSWindow? { window.attachedSheet }
}

/// Before a launch: no window or sheet is ordered on screen. A held alert's buttons answer it with the
/// response AppKit gives (the first button `alertFirstButtonReturn`, then +1); sheets on one window queue.
@MainActor
final class HeldScreen: NSObject, Presenter {
    private struct Held {
        let sheet: NSWindow
        weak var parent: NSWindow?
        let buttons: [NSButton]
        let done: (NSApplication.ModalResponse) -> Void
    }

    private var shown: Set<ObjectIdentifier> = []
    private var held: [Held] = []

    func show(_ controller: NSWindowController) {
        guard let window = controller.window else { return }
        shown.insert(ObjectIdentifier(window))
        NotificationCenter.default.addObserver(self, selector: #selector(closed(_:)),
                                               name: NSWindow.willCloseNotification, object: window)
    }

    @objc private func closed(_ note: Notification) {
        guard let window = note.object as? NSWindow else { return }
        shown.remove(ObjectIdentifier(window))
        NotificationCenter.default.removeObserver(self, name: NSWindow.willCloseNotification, object: window)
    }

    func isShown(_ window: NSWindow) -> Bool { shown.contains(ObjectIdentifier(window)) }

    func begin(_ alert: NSAlert, on window: NSWindow, done: @escaping (NSApplication.ModalResponse) -> Void) {
        alert.layout()
        for button in alert.buttons {
            button.target = self
            button.action = #selector(press(_:))
        }
        held.append(Held(sheet: alert.window, parent: window, buttons: alert.buttons, done: done))
    }

    func begin(_ panel: NSSavePanel, on window: NSWindow, done: @escaping (NSApplication.ModalResponse) -> Void) {
        held.append(Held(sheet: panel, parent: window, buttons: [], done: done))
    }

    @objc private func press(_ button: NSButton) {
        guard let entry = held.first(where: { $0.buttons.contains(button) }),
              let index = entry.buttons.firstIndex(of: button) else { return }
        let first = NSApplication.ModalResponse.alertFirstButtonReturn.rawValue
        finish(entry.sheet, NSApplication.ModalResponse(rawValue: first + index))
    }

    func end(_ sheet: NSWindow, on window: NSWindow, _ code: NSApplication.ModalResponse) {
        finish(sheet, sheet is NSSavePanel ? .cancel : code)
    }

    private func finish(_ sheet: NSWindow, _ code: NSApplication.ModalResponse) {
        guard let index = held.firstIndex(where: { $0.sheet === sheet }) else { return }
        let entry = held.remove(at: index)
        entry.done(code)
    }

    func sheet(on window: NSWindow) -> NSWindow? {
        held.first { $0.parent === window }?.sheet
    }
}
