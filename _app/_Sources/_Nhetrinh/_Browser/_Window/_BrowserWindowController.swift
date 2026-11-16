import AppKit
import NhetrinhCore
import WebKit

/// The one browser window: vertical tab sidebar | toolbar + web view.
/// Tab lifecycle, menu actions and WebKit delegates are in the `BrowserWindowController+…` files;
/// session restore and idle unload are in `../Lifecycle/`; reorder, reopen, links, icons, loading in `../Handling/`.
final class BrowserWindowController: NSWindowController {
    static let homeURL = URL(string: "https://www.google.com")

    var tabs: [Tab] = []
    var selected = -1
    let sidebar = SidebarView()
    let toolbar = ToolbarView()
    let webContainer = NSView()
    let split = NSSplitViewController()
    var unloadTimer: Timer?
    /// Session restore (`../Lifecycle/`): the pending save, where it goes (nil: off), the last sidebar width.
    var saveTimer: Timer?
    var sessionFolder: URL?
    var sidebarWidth = Session.defaultSidebarWidth
    /// P2 (`../Handling/`): tabs to reopen, site icons, where the next background tab goes (nil: after the selected).
    var closedTabs = ClosedTabs()
    let favicons = Favicons()
    var backgroundSlot: Int?
    /// P3 (`../Page/`): the sheets a page asks for, site permissions, links handed to other apps.
    let sheets = Sheets()
    /// P4 (`../Handling/`, `UI/`): the settings (`prefs.json`, nil folder: not saved), the find bar, the Settings Hub.
    var prefs = Prefs()
    var prefsFolder: URL?
    let findBar = FindBar()
    var findBarHeight: NSLayoutConstraint?
    var hub: SettingsHub?
    /// P5 (`../Page/Outside/`): this launch's downloads, shown in the sidebar footer.
    let downloads = Downloads()

    init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1280, height: 820),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered, defer: false)
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.setFrameAutosaveName("nhetrinh.main")
        window.center()
        super.init(window: window)
        buildLayout()
        wireCallbacks()
        startIdleUnloading()
    }

    required init?(coder: NSCoder) { return nil }

    // MARK: - Layout

    private func buildLayout() {
        let sideItem = NSSplitViewItem(sidebarWithViewController: controller(for: sidebar))
        sideItem.minimumThickness = 180
        sideItem.maximumThickness = 420
        sideItem.canCollapse = true
        split.addSplitViewItem(sideItem)
        split.addSplitViewItem(NSSplitViewItem(viewController: controller(for: makeMainView())))
        window?.contentViewController = split
        window?.setContentSize(NSSize(width: 1280, height: 820))
    }

    private func controller(for view: NSView) -> NSViewController {
        let controller = NSViewController()
        controller.view = view
        return controller
    }

    private func makeMainView() -> NSView {
        let main = NSView()
        webContainer.setAccessibilityIdentifier("nhetrinh.web")
        findBar.isHidden = true
        let findHeight = findBar.heightAnchor.constraint(equalToConstant: 0)
        findBarHeight = findHeight
        for view in [toolbar, findBar, webContainer] as [NSView] {
            view.translatesAutoresizingMaskIntoConstraints = false
            main.addSubview(view)
        }
        NSLayoutConstraint.activate([
            toolbar.topAnchor.constraint(equalTo: main.topAnchor),
            toolbar.leadingAnchor.constraint(equalTo: main.leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: main.trailingAnchor),
            toolbar.heightAnchor.constraint(equalToConstant: 40),
            findBar.topAnchor.constraint(equalTo: toolbar.bottomAnchor),
            findBar.leadingAnchor.constraint(equalTo: main.leadingAnchor),
            findBar.trailingAnchor.constraint(equalTo: main.trailingAnchor),
            findHeight,
            webContainer.topAnchor.constraint(equalTo: findBar.bottomAnchor),
            webContainer.leadingAnchor.constraint(equalTo: main.leadingAnchor),
            webContainer.trailingAnchor.constraint(equalTo: main.trailingAnchor),
            webContainer.bottomAnchor.constraint(equalTo: main.bottomAnchor),
        ])
        return main
    }

    private func wireCallbacks() {
        sidebar.onSelect = { [weak self] index in self?.select(index) }
        sidebar.onClose = { [weak self] index in self?.close(at: index) }
        sidebar.onNewTab = { [weak self] in self?.newTab(nil) }
        sidebar.onMove = { [weak self] from, to in self?.moveTab(from: from, to: to) }
        toolbar.onBack = { [weak self] in self?.goBack(nil) }
        toolbar.onForward = { [weak self] in self?.goForward(nil) }
        toolbar.onReload = { [weak self] in self?.reload(nil) }
        toolbar.onStop = { [weak self] in self?.stopLoading(nil) }
        toolbar.onSubmit = { [weak self] text in self?.navigate(text) }
        toolbar.onZoomBadge = { [weak self] in self?.actualSize(nil) }
        findBar.onFind = { [weak self] text, backwards in self?.find(text, backwards: backwards) }
        findBar.onClose = { [weak self] in self?.closeFind() }
        wireDownloads()
    }

    // MARK: - Chrome

    var current: WKWebView? { tabs.indices.contains(selected) ? tabs[selected].webView : nil }

    /// Bring the sidebar, the toolbar and the window title in line with the tabs. Every tab change
    /// passes here, so this is also where the session save is scheduled.
    func refreshChrome() {
        sessionChanged()
        sidebar.update(tabs.map { SidebarView.Row(title: $0.title, loaded: $0.isLoaded, icon: $0.icon) },
                       selected: selected)
        guard tabs.indices.contains(selected) else { return }
        let tab = tabs[selected]
        toolbar.update(url: tab.url, canBack: tab.webView?.canGoBack ?? false,
                       canForward: tab.webView?.canGoForward ?? false)
        refreshLoading()
        toolbar.showZoom(Zoom.badge(Double(tab.webView?.pageZoom ?? 1)))
        window?.title = tab.title
    }
}
