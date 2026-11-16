import WebKit

/// WebKit callbacks: page events, popups, links for a background tab, links to other apps, failures.
/// P3's dialogs, panels, sign-in and error page are in `../Page/`.
extension BrowserWindowController: WKNavigationDelegate, WKUIDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {  // force: WebKit's signature
        Bench.reportFirstLoad()
        findIcon(of: webView)
    }

    /// A page committed: its host's zoom (P4).
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {  // force: WebKit's signature
        applySavedZoom(to: webView)
    }

    /// ⌘-click on a link: the page stays, the link opens in a background tab (P2).
    func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        let followed = action.navigationType == .linkActivated || action.targetFrame?.isMainFrame != false
        if let url = action.request.url, leaves(url, from: webView, asked: followed) {
            return decisionHandler(.cancel)
        }
        if action.navigationType == .linkActivated, action.modifierFlags.contains(.command),
           let url = action.request.url, Self.opensInBackground(url) {
            decisionHandler(.cancel)
            openInBackground(url)
            return
        }
        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!,  // force: WebKit's
                 withError error: Error) {
        Log.web.error("load failed before the page started: \(error.localizedDescription, privacy: .public)")
        showErrorPage(for: error, in: webView)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!,  // force: WebKit's signature
                 withError error: Error) {
        Log.web.error("load failed: \(error.localizedDescription, privacy: .public)")
        showErrorPage(for: error, in: webView)
    }

    /// target=_blank and window.open become a new tab that adopts the web view WebKit asks for.
    /// Open Link in New Tab and a ⌘-click on a target=_blank link open a background tab instead: it
    /// loads when it is first selected, so WebKit gets no web view (P2).
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration,
                 for action: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if let url = action.request.url, leaves(url, from: webView, asked: true) { return nil }
        let menuAsked = (webView as? BrowserWebView)?.takesBackgroundOpen() ?? false
        if menuAsked || action.modifierFlags.contains(.command), let url = action.request.url,
           Self.opensInBackground(url) {
            openInBackground(url)
            return nil
        }
        let popup = BrowserWebView(frame: .zero, configuration: configuration)
        let tab = Tab(url: action.request.url)
        load(tab, adopting: popup)
        tree.insert(tab, atFlat: tabs.count)
        select(tabs.count - 1)
        return popup
    }

    func webViewDidClose(_ webView: WKWebView) {
        if let index = tabs.firstIndex(where: { $0.webView === webView }) { close(at: index) }
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        Log.web.error("the page process ended; reloading the tab")
        webView.reload()
    }
}
