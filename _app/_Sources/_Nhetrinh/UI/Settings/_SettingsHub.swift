import AppKit
import NhetrinhCore
import WebKit

/// The Settings Hub (D19): one small native window, nhetrinh > Settings Hub… (⌘,). Appearance, Sidebar
/// position (P8-SIDE-1), Search engine, Unload idle tabs after N minutes, Remember sign-ins after quit
/// (P9-REMEMBER), Remember history (P11-HISTORY), Clear Website Data…. Every change
/// applies at once; the browser keeps it (`PrefsKeeping`). Actions and the readback probe's presses:
/// `SettingsHub+Actions`.
final class SettingsHub: NSWindowController {
    static let title = "Settings Hub"
    static let clearTitle = "Clear Website Data…"
    static let positionTitle = "Sidebar position"
    static let rememberTitle = "Remember sign-ins after quit"
    static let historyTitle = "Remember history"
    /// The browser applies and saves a change.
    var onChange: (((inout Prefs) -> Void) -> Void)?
    /// Clear All: the browser deletes the kept sign-ins (P9-REMEMBER).
    var onForgetSignIns: (() -> Void)?
    /// Clear All: the browser empties the history (P11-HISTORY).
    var onForgetHistory: (() -> Void)?
    let store: WKWebsiteDataStore
    let appearance = NSPopUpButton()
    let engine = NSPopUpButton()
    let position = NSPopUpButton()
    let minutes = NSTextField()
    lazy var clear = NSButton(title: Self.clearTitle, target: self, action: #selector(askToClear))
    lazy var remember = NSButton(checkboxWithTitle: Self.rememberTitle, target: self,
                                 action: #selector(rememberToggled))
    lazy var keepHistory = NSButton(checkboxWithTitle: Self.historyTitle, target: self,
                                    action: #selector(historyToggled))
    /// The prefs shown last: a bad minutes value goes back to it.
    var shown = Prefs()

    init(store: WKWebsiteDataStore) {
        self.store = store
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 420, height: 270),
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
        position.addItems(withTitles: SidebarSide.allCases.map(\.title))
        position.target = self
        position.action = #selector(sideChosen)
        engine.addItems(withTitles: SearchEngine.allCases.map(\.title))
        engine.target = self
        engine.action = #selector(engineChosen)
        minutes.target = self
        minutes.action = #selector(minutesTyped)
        minutes.widthAnchor.constraint(equalToConstant: 60).isActive = true
        let grid = makeGrid()
        let content = NSView()
        content.addSubview(grid)
        NSLayoutConstraint.activate([
            grid.centerXAnchor.constraint(equalTo: content.centerXAnchor),
            grid.centerYAnchor.constraint(equalTo: content.centerYAnchor),
        ])
        AppFont.apply(to: AppFont.controls(in: content))
        window.contentView = content
    }

    private func makeGrid() -> NSGridView {
        let idle = NSStackView(views: [minutes, NSTextField(labelWithString: "minutes")])
        let grid = NSGridView(views: [
            [label("Appearance"), appearance], [label(Self.positionTitle), position], [label("Search engine"), engine],
            [label("Unload idle tabs after"), idle], [label("Sign-ins"), remember],
            [label("History"), keepHistory],
            [NSGridCell.emptyContentView, clear],
        ])
        grid.rowSpacing = 12
        grid.column(at: 0).xPlacement = .trailing
        grid.translatesAutoresizingMaskIntoConstraints = false
        return grid
    }

    /// Every label, menu, field and button of the hub, in the app's font (P8-FONT-1).
    var textControls: [NSControl] { window?.contentView.map(AppFont.controls(in:)) ?? [] }

    private func label(_ text: String) -> NSTextField { NSTextField(labelWithString: text + ":") }

    /// Show `prefs` in the controls.
    func show(_ prefs: Prefs) {
        shown = prefs
        appearance.selectItem(withTitle: prefs.appearance.title)
        position.selectItem(withTitle: prefs.sidebarSide.title)
        engine.selectItem(withTitle: prefs.searchEngine.title)
        minutes.integerValue = prefs.idleUnloadMinutes
        remember.state = prefs.rememberSignIns ? .on : .off
        keepHistory.state = prefs.rememberHistory ? .on : .off
    }
}
