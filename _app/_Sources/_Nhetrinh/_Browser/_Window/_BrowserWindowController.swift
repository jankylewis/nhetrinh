import AppKit
import WebKit

/// The one browser window: vertical tab sidebar | toolbar + web view.
/// Tab lifecycle, menu actions and WebKit delegates are in the `BrowserWindowController+…` files.
final class BrowserWindowController: NSWindowController {
    static let homeURL = URL(string: "https://www.google.com")
    static let unloadAfter: TimeInterval = 10 * 60

    var tabs: [Tab] = []
    var selected = -1
    let sidebar = SidebarView()
    let toolbar = ToolbarView()
    let webContainer = NSView()
    let split = NSSplitViewController()
    private var unloadTimer: Timer?

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
        for view in [toolbar, webContainer] as [NSView] {
            view.translatesAutoresizingMaskIntoConstraints = false
            main.addSubview(view)
        }
        NSLayoutConstraint.activate([
            toolbar.topAnchor.constraint(equalTo: main.topAnchor),
            toolbar.leadingAnchor.constraint(equalTo: main.leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: main.trailingAnchor),
            toolbar.heightAnchor.constraint(equalToConstant: 40),
            webContainer.topAnchor.constraint(equalTo: toolbar.bottomAnchor),
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
        toolbar.onBack = { [weak self] in self?.goBack(nil) }
        toolbar.onForward = { [weak self] in self?.goForward(nil) }
        toolbar.onReload = { [weak self] in self?.reload(nil) }
        toolbar.onSubmit = { [weak self] text in self?.navigate(text) }
    }

    /// Once a minute, unload background tabs that were not used for `unloadAfter`.
    private func startIdleUnloading() {
        guard !Bench.loadAll else { return }
        unloadTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.unloadIdleTabs()
        }
    }

    // MARK: - Chrome

    var current: WKWebView? { tabs.indices.contains(selected) ? tabs[selected].webView : nil }

    /// Bring the sidebar, the toolbar and the window title in line with the tabs.
    func refreshChrome() {
        sidebar.update(titles: tabs.map(\.title), loaded: tabs.map(\.isLoaded), selected: selected)
        guard tabs.indices.contains(selected) else { return }
        let tab = tabs[selected]
        toolbar.update(url: tab.url, canBack: tab.webView?.canGoBack ?? false,
                       canForward: tab.webView?.canGoForward ?? false)
        window?.title = tab.title
    }
}
