import AppKit
import NhetrinhCore
import WebKit

/// The Settings Hub (D19): one small native window, nhetrinh > Settings Hub… (⌘,). Appearance, Search
/// engine, Unload idle tabs after N minutes, Clear Website Data…. Every change applies at once; the
/// browser keeps it (`PrefsKeeping`). Actions and the readback probe's presses: `SettingsHub+Actions`.
final class SettingsHub: NSWindowController {
    static let title = "Settings Hub"
    static let clearTitle = "Clear Website Data…"
    /// The browser applies and saves a change.
    var onChange: (((inout Prefs) -> Void) -> Void)?
    let store: WKWebsiteDataStore
    let appearance = NSPopUpButton()
    let engine = NSPopUpButton()
    let minutes = NSTextField()
    lazy var clear = NSButton(title: Self.clearTitle, target: self, action: #selector(askToClear))
    /// The prefs shown last: a bad minutes value goes back to it.
    var shown = Prefs()

    init(store: WKWebsiteDataStore) {
        self.store = store
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 420, height: 180),
                              styleMask: [.titled, .closable], backing: .buffered, defer: false)
        window.title = Self.title
        window.isReleasedWhenClosed = false
        super.init(window: window)
        layOut(in: window)
        window.center()
    }

    required init?(coder: NSCoder) { return nil }

    private func layOut(in window: NSWindow) {
        appearance.addItems(withTitles: Appearance.allCases.map(\.title))
        appearance.target = self
        appearance.action = #selector(appearanceChosen)
        engine.addItems(withTitles: SearchEngine.allCases.map(\.title))
        engine.target = self
        engine.action = #selector(engineChosen)
        minutes.target = self
        minutes.action = #selector(minutesTyped)
        minutes.widthAnchor.constraint(equalToConstant: 60).isActive = true
        let idle = NSStackView(views: [minutes, NSTextField(labelWithString: "minutes")])
        let grid = NSGridView(views: [
            [label("Appearance"), appearance], [label("Search engine"), engine],
            [label("Unload idle tabs after"), idle], [NSGridCell.emptyContentView, clear],
        ])
        grid.rowSpacing = 12
        grid.column(at: 0).xPlacement = .trailing
        grid.translatesAutoresizingMaskIntoConstraints = false
        let content = NSView()
        content.addSubview(grid)
        NSLayoutConstraint.activate([
            grid.centerXAnchor.constraint(equalTo: content.centerXAnchor),
            grid.centerYAnchor.constraint(equalTo: content.centerYAnchor),
        ])
        window.contentView = content
    }

    private func label(_ text: String) -> NSTextField { NSTextField(labelWithString: text + ":") }

    /// Show `prefs` in the controls.
    func show(_ prefs: Prefs) {
        shown = prefs
        appearance.selectItem(withTitle: prefs.appearance.title)
        engine.selectItem(withTitle: prefs.searchEngine.title)
        minutes.integerValue = prefs.idleUnloadMinutes
    }
}
