import AppKit
import NhetrinhCore
import WebKit

/// Tab lifecycle: open, select, load on first use, close, unload when idle.
extension BrowserWindowController {
    func openInitialTabs() {
        let urls = Bench.urls.isEmpty ? [Self.homeURL].compactMap { $0 } : Bench.urls
        tabs = urls.map { Tab(url: $0, title: $0.host ?? $0.absoluteString) }
        if tabs.isEmpty { tabs = [Tab(url: nil)] }
        select(0)
        if Bench.loadAll { loadRemainingTabs(from: 1) }
        Bench.startPolling { [weak self] in self?.current }
    }

    /// Measurement only: load the other tabs one at a time, never in a burst (NT-ENV-001).
    private func loadRemainingTabs(from index: Int) {
        guard tabs.indices.contains(index) else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + Bench.loadGap) { [weak self] in
            guard let self, self.tabs.indices.contains(index) else { return }
            self.load(self.tabs[index])
            self.refreshChrome()
            self.loadRemainingTabs(from: index + 1)
        }
    }

    func select(_ index: Int) {
        guard tabs.indices.contains(index) else { return }
        if tabs.indices.contains(selected) { tabs[selected].webView?.removeFromSuperview() }
        selected = index
        let tab = tabs[index]
        tab.lastActive = Date()
        load(tab)
        if let webView = tab.webView {
            webView.frame = webContainer.bounds
            webView.autoresizingMask = [.width, .height]
            webContainer.addSubview(webView)
            window?.makeFirstResponder(tab.url == nil ? toolbar.address : webView)
        }
        refreshChrome()
    }

    /// Create the web view on first use: a tab that was never opened costs no process.
    /// `adopted` is a web view WebKit made for a popup; it already carries its own request.
    func load(_ tab: Tab, adopting adopted: WKWebView? = nil) {
        guard tab.webView == nil else { return }
        let webView = adopted ?? WKWebView(frame: .zero, configuration: WebConfig.shared)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        tab.webView = webView
        observe(webView, for: tab)
        if adopted == nil, let url = tab.url { webView.load(URLRequest(url: url)) }
    }

    /// Keep the tab's title and URL, and the toolbar buttons, in step with the page.
    private func observe(_ webView: WKWebView, for tab: Tab) {
        tab.observers = [
            webView.observe(\.title) { [weak self, weak tab] view, _ in
                guard let tab, let title = view.title, !title.isEmpty else { return }
                tab.title = title
                self?.refreshChrome()
            },
            webView.observe(\.url) { [weak self, weak tab] view, _ in
                tab?.url = view.url ?? tab?.url
                self?.refreshChrome()
            },
            webView.observe(\.canGoBack) { [weak self] _, _ in self?.refreshChrome() },
            webView.observe(\.canGoForward) { [weak self] _, _ in self?.refreshChrome() },
        ]
    }

    func close(at index: Int) {
        guard tabs.indices.contains(index) else { return }
        tabs[index].unload()
        tabs.remove(at: index)
        if tabs.isEmpty {
            window?.close()
            return
        }
        selected = -1
        select(min(index, tabs.count - 1))
    }

    func unloadIdleTabs() {
        let cutoff = Date().addingTimeInterval(-Self.unloadAfter)
        for (index, tab) in tabs.enumerated() where index != selected && tab.isLoaded && tab.lastActive < cutoff {
            tab.unload()
        }
        refreshChrome()
    }

    /// Address bar text: go to the URL, or search for the words.
    func navigate(_ text: String) {
        guard let url = AddressParser.url(from: text), tabs.indices.contains(selected) else { return }
        let tab = tabs[selected]
        tab.url = url
        if let webView = tab.webView {
            webView.load(URLRequest(url: url))
        } else {
            select(selected)
        }
        window?.makeFirstResponder(tab.webView)
    }
}
