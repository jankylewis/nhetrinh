import AppKit
import NhetrinhCore
import WebKit

/// Tab lifecycle: open, select, load on first use, close. Restore and idle unload: `../Lifecycle/`.
extension BrowserWindowController {
    /// The saved session (P1), or with NHT_BENCH_URLS the seeded tabs (no session read or written).
    func openInitialTabs() {
        defer { Bench.startPolling { [weak self] in self?.current } }
        loadPrefs(from: Self.sessionFolder())
        keepHistory(in: Self.sessionFolder())  // P11-HISTORY: the profile's folder once P10 lands
        if let folder = Self.sessionFolder(), let home = Self.homeURL {
            openSavedSession(in: folder, home: home)
            return
        }
        let urls = Bench.urls.isEmpty ? [Self.homeURL].compactMap { $0 } : Bench.urls
        tabs = urls.map { Tab(url: $0, title: $0.host ?? $0.absoluteString) }
        if tabs.isEmpty { tabs = [Tab(url: nil)] }
        select(0)
        if Bench.loadAll { loadRemainingTabs(from: 1) }
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
        if tabs.indices.contains(selected) {
            if selected != index { endSheets(of: tabs[selected].webView) }  // a page's sheet ends with it (S1)
            tabs[selected].webView?.removeFromSuperview()
            tabs[selected].lastActive = Date()  // idle from the moment it is left
        }
        selected = index
        backgroundSlot = nil
        findBar.show(found: nil)  // the answer belongs to the page that was searched (F5)
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
    /// A tab unloaded before gets its `interactionState` back: its history and scroll position.
    func load(_ tab: Tab, adopting adopted: WKWebView? = nil) {
        guard tab.webView == nil else { return }
        let webView = adopted ?? BrowserWebView(frame: .zero, configuration: WebConfig.shared)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        webView.allowsMagnification = true  // pinch (P4); not kept per site, View > Zoom is
        if #available(macOS 13.3, *) { webView.isInspectable = true }  // Safari's Develop menu (DECISIONS.md Q3)
        tab.webView = webView
        observe(webView, for: tab)
        guard adopted == nil else { return }
        if let state = tab.savedState {
            tab.savedState = nil
            webView.interactionState = state
        } else if let url = tab.url {
            webView.load(URLRequest(url: url))
        }
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
            webView.observe(\.isLoading) { [weak self] _, _ in self?.refreshLoading() },
            webView.observe(\.estimatedProgress) { [weak self] _, _ in self?.refreshLoading() },
        ]
    }

    /// Close a tab, kept for File > Reopen Closed Tab. The selection stays unless the selected tab closes.
    func close(at index: Int) {
        guard tabs.indices.contains(index) else { return }
        let tab = tabs[index]
        endSheets(of: tab.webView)  // S1
        tab.unload()
        let path = tree.path(ofFlat: index)
        let groups = path.map { tree.groupNames(along: $0.parent) } ?? []
        if let url = tab.url {  // its place in the tree, for Reopen Closed Tab (P7-FIX-1, P1; nested: P8-GROUPS-1)
            closedTabs.push(ClosedTab(url: url, title: tab.title, index: index, path: path, groups: groups))
        }
        tree.removeTab(atFlat: index)  // its groups stay, even empty (P7)
        if let slot = backgroundSlot, index < slot { backgroundSlot = slot - 1 }  // NT-UIX-003
        if tabs.isEmpty {
            window?.close()
            return
        }
        guard index == selected else {  // a row closed from its button, menu or a middle click (P2)
            if index < selected { selected -= 1 }
            return refreshChrome()
        }
        selected = -1
        select(tree.nearestVisible(afterRemoving: index) ?? 0)  // a tab the user sees (P7-FIX-1, P2)
    }

    /// Address bar text: go to the URL, or search for the words.
    func navigate(_ text: String) {
        guard let url = AddressParser.url(from: text, engine: prefs.searchEngine),
              tabs.indices.contains(selected) else { return }
        let tab = tabs[selected]
        tab.url = url
        tab.savedState = nil  // a new address replaces the history kept at unload
        markTyped()  // P11-HISTORY: typed or picked in the address bar
        if let webView = tab.webView {
            webView.load(URLRequest(url: url))
        } else {
            select(selected)
        }
        window?.makeFirstResponder(tab.webView)
    }
}
