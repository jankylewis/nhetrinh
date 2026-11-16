import AppKit
import WebKit

/// A tab's web view. Its context menu reads "Open Link in New Tab" where WebKit's reads "Open Link in
/// New Window" (P2). The item still runs WebKit's own action, which asks the controller for a new web
/// view (`createWebViewWith`); `takesBackgroundOpen()` then says to open it as a background tab.
final class BrowserWebView: WKWebView {
    static let newTabTitle = "Open Link in New Tab"
    static let newWindowIdentifier = "WKMenuItemIdentifierOpenLinkInNewWindow"
    /// WebKit asks for the new web view after a round trip to the page process: the request is
    /// honoured for this long after the item was pressed.
    private static let backgroundWindow: TimeInterval = 3
    private var backgroundUntil: Date?
    /// The items of the last context menu shown, as shown (read by the readback probe).
    private(set) var lastMenu: [String] = []
    /// The readback probe's item to press once the next context menu is shown (R17); nil for the user.
    var pressOnOpen: String?
    /// The user's last click or key in the page: a download soon after is the user's (P5-FIX-1, F2).
    private(set) var lastInput: Date?

    override func mouseDown(with event: NSEvent) {
        lastInput = Date()
        super.mouseDown(with: event)
    }

    override func rightMouseDown(with event: NSEvent) {
        lastInput = Date()
        super.rightMouseDown(with: event)
    }

    override func otherMouseDown(with event: NSEvent) {
        lastInput = Date()
        super.otherMouseDown(with: event)
    }

    override func keyDown(with event: NSEvent) {
        lastInput = Date()
        super.keyDown(with: event)
    }

    override func willOpenMenu(_ menu: NSMenu, with event: NSEvent) {
        super.willOpenMenu(menu, with: event)
        rewrite(menu)
        lastMenu = menu.items.filter { !$0.isSeparatorItem }.map(\.title)
        guard let title = pressOnOpen, let index = menu.items.firstIndex(where: { $0.title == title }) else { return }
        pressOnOpen = nil
        RunLoop.main.perform(inModes: [.eventTracking, .default]) {
            menu.performActionForItem(at: index)
            menu.cancelTracking()
        }
    }

    /// Replace WebKit's "Open Link in New Window" item with ours; WebKit's item rides along with it.
    func rewrite(_ menu: NSMenu) {
        guard let index = menu.items.firstIndex(where: { $0.identifier?.rawValue == Self.newWindowIdentifier })
        else { return }
        let original = menu.items[index]
        let item = NSMenuItem(title: Self.newTabTitle, action: #selector(openLinkInNewTab(_:)), keyEquivalent: "")
        item.target = self
        item.representedObject = original
        menu.removeItem(at: index)
        menu.insertItem(item, at: index)
    }

    @objc func openLinkInNewTab(_ sender: NSMenuItem) {
        guard let original = sender.representedObject as? NSMenuItem, let action = original.action else { return }
        backgroundUntil = Date().addingTimeInterval(Self.backgroundWindow)
        NSApp.sendAction(action, to: original.target, from: original)
    }

    /// Whether the new web view WebKit asks for now comes from "Open Link in New Tab"; asked once.
    func takesBackgroundOpen(now: Date = Date()) -> Bool {
        defer { backgroundUntil = nil }
        return backgroundUntil.map { now <= $0 } ?? false
    }
}
