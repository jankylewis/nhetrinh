import WebKit

/// WebKit callbacks: page events, popups, and failures (logged; the error page comes with P3).
extension BrowserWindowController: WKNavigationDelegate, WKUIDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {  // force: WebKit's signature
        Bench.reportFirstLoad()
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!,  // force: WebKit's
                 withError error: Error) {
        Log.web.error("load failed before the page started: \(error.localizedDescription, privacy: .public)")
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!,  // force: WebKit's signature
                 withError error: Error) {
        Log.web.error("load failed: \(error.localizedDescription, privacy: .public)")
    }

    /// target=_blank and window.open become a new tab that adopts the web view WebKit asks for.
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration,
                 for action: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        let popup = WKWebView(frame: .zero, configuration: configuration)
        let tab = Tab(url: action.request.url)
        load(tab, adopting: popup)
        tabs.append(tab)
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
