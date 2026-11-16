import WebKit

/// One tab. The web view is created lazily and dropped when the tab is unloaded;
/// url + title survive so the sidebar row stays and reload is one click away.
final class Tab {
    var url: URL?
    var title: String
    var webView: WKWebView?
    var lastActive = Date()
    var observers: [NSKeyValueObservation] = []

    init(url: URL?, title: String = "New Tab") {
        self.url = url
        self.title = title
    }

    var isLoaded: Bool { webView != nil }

    func unload() {
        guard let wv = webView else { return }
        url = wv.url ?? url
        observers.removeAll()
        wv.stopLoading()
        wv.removeFromSuperview()
        webView = nil
    }
}
