import AppKit
import NhetrinhCore
import WebKit

/// The one browser window: vertical tab sidebar | toolbar + web view.
final class BrowserWindowController: NSWindowController {
    static let homeURL = URL(string: "https://www.google.com")!
    static let unloadAfter: TimeInterval = 10 * 60

    var tabs: [Tab] = []
    var selected = -1
    let sidebar = SidebarView()
    let toolbar = ToolbarView()
    let webContainer = NSView()
    let split = NSSplitViewController()
    var unloadTimer: Timer?

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
        if !Bench.loadAll {
            unloadTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
                self?.unloadIdleTabs()
            }
        }
    }

    required init?(coder: NSCoder) { fatalError("not used") }

    private func buildLayout() {
        let sideVC = NSViewController()
        sideVC.view = sidebar
        let sideItem = NSSplitViewItem(sidebarWithViewController: sideVC)
        sideItem.minimumThickness = 180
        sideItem.maximumThickness = 420
        sideItem.canCollapse = true

        let mainVC = NSViewController()
        let main = NSView()
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        webContainer.translatesAutoresizingMaskIntoConstraints = false
        main.addSubview(toolbar)
        main.addSubview(webContainer)
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
        mainVC.view = main
        split.addSplitViewItem(sideItem)
        split.addSplitViewItem(NSSplitViewItem(viewController: mainVC))
        window?.contentViewController = split
        window?.setContentSize(NSSize(width: 1280, height: 820))

        sidebar.onSelect = { [weak self] i in self?.select(i) }
        sidebar.onClose = { [weak self] i in self?.close(at: i) }
        sidebar.onNewTab = { [weak self] in self?.newTab(nil) }
        toolbar.onBack = { [weak self] in self?.goBack(nil) }
        toolbar.onForward = { [weak self] in self?.goForward(nil) }
        toolbar.onReload = { [weak self] in self?.reload(nil) }
        toolbar.onSubmit = { [weak self] text in self?.navigate(text) }
    }

    func openInitialTabs() {
        let urls = Bench.urls.isEmpty ? [Self.homeURL] : Bench.urls
        urls.forEach { tabs.append(Tab(url: $0, title: $0.host ?? $0.absoluteString)) }
        if Bench.loadAll { tabs.indices.forEach { load(tabs[$0]) } }
        select(0)
        Bench.startPolling { [weak self] in self?.current }
    }

    // MARK: - Tab lifecycle

    func select(_ i: Int) {
        guard tabs.indices.contains(i) else { return }
        if tabs.indices.contains(selected) { tabs[selected].webView?.removeFromSuperview() }
        selected = i
        let tab = tabs[i]
        tab.lastActive = Date()
        load(tab)
        if let wv = tab.webView {
            wv.frame = webContainer.bounds
            wv.autoresizingMask = [.width, .height]
            webContainer.addSubview(wv)
            window?.makeFirstResponder(tab.url == nil ? toolbar.address : wv)
        }
        refreshChrome()
    }

    /// Creates the web view on first use (lazy tabs: an unopened tab costs no process).
    func load(_ tab: Tab, webView given: WKWebView? = nil) {
        guard tab.webView == nil else { return }
        let wv = given ?? WKWebView(frame: .zero, configuration: WebConfig.shared)
        wv.navigationDelegate = self
        wv.uiDelegate = self
        wv.allowsBackForwardNavigationGestures = true
        tab.webView = wv
        tab.observers = [
            wv.observe(\.title) { [weak self, weak tab] w, _ in
                guard let tab, let t = w.title, !t.isEmpty else { return }
                tab.title = t
                self?.refreshChrome()
            },
            wv.observe(\.url) { [weak self, weak tab] w, _ in
                tab?.url = w.url ?? tab?.url
                self?.refreshChrome()
            },
            wv.observe(\.canGoBack) { [weak self] _, _ in self?.refreshChrome() },
            wv.observe(\.canGoForward) { [weak self] _, _ in self?.refreshChrome() },
        ]
        if given == nil, let url = tab.url { wv.load(URLRequest(url: url)) }
    }

    func close(at i: Int) {
        guard tabs.indices.contains(i) else { return }
        tabs[i].unload()
        tabs.remove(at: i)
        if tabs.isEmpty { window?.close(); return }
        selected = -1
        select(min(i, tabs.count - 1))
    }

    func unloadIdleTabs() {
        let cutoff = Date().addingTimeInterval(-Self.unloadAfter)
        for (i, tab) in tabs.enumerated() where i != selected && tab.isLoaded && tab.lastActive < cutoff {
            tab.unload()
        }
        refreshChrome()
    }

    func refreshChrome() {
        sidebar.update(titles: tabs.map(\.title), loaded: tabs.map(\.isLoaded), selected: selected)
        guard tabs.indices.contains(selected) else { return }
        let tab = tabs[selected]
        toolbar.update(url: tab.url, canBack: tab.webView?.canGoBack ?? false,
                       canForward: tab.webView?.canGoForward ?? false)
        window?.title = tab.title
    }

    func navigate(_ text: String) {
        guard let url = AddressParser.url(from: text), tabs.indices.contains(selected) else { return }
        let tab = tabs[selected]
        tab.url = url
        if let wv = tab.webView { wv.load(URLRequest(url: url)) } else { select(selected) }
        window?.makeFirstResponder(tab.webView)
    }

    // MARK: - Menu actions (responder chain)

    @objc func newTab(_ sender: Any?) {
        tabs.append(Tab(url: nil))
        select(tabs.count - 1)
        focusAddress(nil)
    }

    @objc func closeTab(_ sender: Any?) { close(at: selected) }
    @objc func focusAddress(_ sender: Any?) { window?.makeFirstResponder(toolbar.address) }
    @objc func reload(_ sender: Any?) { current?.reload() }
    @objc func goBack(_ sender: Any?) { current?.goBack() }
    @objc func goForward(_ sender: Any?) { current?.goForward() }

    @objc func selectTabByNumber(_ sender: NSMenuItem) {
        select(sender.tag == 9 ? tabs.count - 1 : sender.tag - 1)
    }

    @objc func toggleTabSidebar(_ sender: Any?) {
        split.splitViewItems.first?.animator().isCollapsed.toggle()
    }

    var current: WKWebView? { tabs.indices.contains(selected) ? tabs[selected].webView : nil }
}

// MARK: - WebKit delegates

extension BrowserWindowController: WKNavigationDelegate, WKUIDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        Bench.reportFirstLoad()
    }

    /// target=_blank and window.open -> a new tab that reuses WebKit's configuration.
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration,
                 for action: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        let wv = WKWebView(frame: .zero, configuration: configuration)
        let tab = Tab(url: action.request.url)
        load(tab, webView: wv)
        tabs.append(tab)
        select(tabs.count - 1)
        return wv
    }

    func webViewDidClose(_ webView: WKWebView) {
        if let i = tabs.firstIndex(where: { $0.webView === webView }) { close(at: i) }
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) { webView.reload() }
}
