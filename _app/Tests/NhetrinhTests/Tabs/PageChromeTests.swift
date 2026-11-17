import AppKit
import Testing
import WebKit
@testable import Nhetrinh

/// P2 page chrome: the link menu's Open Link in New Tab, reload that becomes stop. No page loads.
@MainActor
struct PageChromeTests {
    private final class Sink: NSObject {
        var hits = 0
        @objc func hit(_ sender: Any?) { hits += 1 }
    }

    private func linkMenu(_ sink: Sink) -> (NSMenu, NSMenuItem) {
        let menu = NSMenu()
        let original = NSMenuItem(title: "Open Link in New Window", action: #selector(Sink.hit(_:)), keyEquivalent: "")
        original.identifier = NSUserInterfaceItemIdentifier(BrowserWebView.newWindowIdentifier)
        original.target = sink
        menu.addItem(NSMenuItem(title: "Open Link", action: nil, keyEquivalent: ""))
        menu.addItem(original)
        menu.addItem(NSMenuItem(title: "Copy Link", action: nil, keyEquivalent: ""))
        return (menu, original)
    }

    @Test func linkMenuSaysNewTabWhereWebKitSaysNewWindow() {
        let view = BrowserWebView(frame: .zero, configuration: WKWebViewConfiguration())
        let (menu, original) = linkMenu(Sink())
        view.rewrite(menu)
        #expect(menu.items.map(\.title) == ["Open Link", "Open Link in New Tab", "Copy Link"])
        #expect(menu.items[1].representedObject as? NSMenuItem === original)
    }

    @Test func aMenuWithoutTheLinkItemStaysAsItIs() {
        let view = BrowserWebView(frame: .zero, configuration: WKWebViewConfiguration())
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Reload", action: nil, keyEquivalent: ""))
        view.rewrite(menu)
        #expect(menu.items.map(\.title) == ["Reload"])
    }

    /// Our item runs WebKit's own, and the web view WebKit then asks for is a background tab, once.
    @Test(arguments: [(0.0, true), (2.0, true), (10.0, false)])
    func newTabItemRunsWebKitsItemAndAsksForABackgroundTab(after: Double, background: Bool) {
        _ = NSApplication.shared
        let view = BrowserWebView(frame: .zero, configuration: WKWebViewConfiguration())
        let sink = Sink()
        let (menu, _) = linkMenu(sink)
        view.rewrite(menu)
        menu.performActionForItem(at: 1)
        #expect(sink.hits == 1)
        #expect(view.takesBackgroundOpen(now: Date().addingTimeInterval(after)) == background)
        #expect(view.takesBackgroundOpen() == false)
    }

    @Test func reloadIsStopWhileThePageLoads() {
        let toolbar = ToolbarView()
        var stops = 0, reloads = 0
        toolbar.onStop = { stops += 1 }
        toolbar.onReload = { reloads += 1 }
        #expect(toolbar.reloadLabel == "Reload")
        toolbar.showLoading(true, progress: 0.3)
        #expect(toolbar.reloadLabel == "Stop" && toolbar.press("Stop") && !toolbar.press("Reload"))
        toolbar.showLoading(false, progress: 1)
        #expect(toolbar.reloadLabel == "Reload" && toolbar.press("Reload"))
        #expect(stops == 1 && reloads == 1)
    }
}

/// P8-FONT-1 (headmate request): the app's own labels and fields are in Menlo, each at its own point size;
/// with no Menlo, the system monospaced font. One helper (`AppFont`) makes the font. Red first.
@MainActor
struct ChromeFontTests {
    static func chrome() -> [String: [NSControl]] {
        _ = NSApplication.shared
        let folder = SidebarNode.nodes([.folder(name: "work", collapsed: true, marked: true, tabs: [])])[0]
        return [
            "sidebar row": TabRowView().textControls, "folder row": FolderRowView().shown(folder).textControls,
            "New Tab": SidebarView().textControls, "address bar": ToolbarView().textControls,
            "find bar": FindBar().textControls, "Settings Hub": SettingsHub(store: .nonPersistent()).textControls,
            "downloads": DownloadRow().textControls,
        ]
    }

    @Test(arguments: ["sidebar row", "folder row", "New Tab", "address bar", "find bar", "Settings Hub", "downloads"])
    func everyTextControlIsMenlo(name: String) throws {
        let controls = try #require(Self.chrome()[name])
        #expect(!controls.isEmpty)
        #expect(controls.map { $0.font?.familyName } == controls.map { _ in "Menlo" }, "\(name)")
        #expect(AppFont.family(of: controls) == "Menlo")
    }

    @Test(arguments: [9.0, 11.0, 13.0, 17.0])
    func applyKeepsThePointSize(size: Double) {
        let field = NSTextField(labelWithString: "a")
        field.font = .systemFont(ofSize: size)
        AppFont.apply(to: [field])
        #expect(field.font?.familyName == "Menlo" && field.font?.pointSize == CGFloat(size))
    }

    @Test(arguments: [false, true])
    func aMissingFamilyFallsBackToTheSystemMonospacedFont(bold: Bool) {
        let font = AppFont.font(size: 12, bold: bold, family: "No Such Family nhetrinh")
        let system = NSFont.monospacedSystemFont(ofSize: 12, weight: bold ? .bold : .regular)
        #expect(font.familyName == system.familyName && font.pointSize == 12)
    }

    /// A marked folder's name is bold Menlo; two families read as "mixed", none as "".
    @Test func boldIsMenloAndMixedFamiliesAreNamed() {
        #expect(NSFontManager.shared.traits(of: AppFont.font(size: 13, bold: true)).contains(.boldFontMask))
        let other = NSTextField(labelWithString: "b")
        other.font = .systemFont(ofSize: 13)
        let menlo = NSTextField(labelWithString: "a")
        AppFont.apply(to: [menlo])
        #expect(AppFont.family(of: [menlo, other]).hasPrefix("mixed: "))
        #expect(AppFont.family(of: []) == "")
    }
}
