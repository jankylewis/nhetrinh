import WebKit

/// One tab. The web view is created on first use and dropped when the tab is unloaded.
/// The URL and the title stay, so the sidebar row remains and one click loads the page again.
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
        guard let webView else { return }
        url = webView.url ?? url
        observers.removeAll()
        webView.stopLoading()
        webView.removeFromSuperview()
        self.webView = nil
    }
}
