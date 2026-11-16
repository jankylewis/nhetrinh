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

/// One configuration for every tab: shared cookies, cache and process policy.
enum WebConfig {
    static let shared: WKWebViewConfiguration = {
        let c = WKWebViewConfiguration()
        c.websiteDataStore = .default()
        // Safari-like UA tail, so sites (e.g. Google sign-in) treat us as Safari.
        c.applicationNameForUserAgent = "Version/18.0 Safari/605.1.15"
        return c
    }()
}

/// Address bar input -> URL. Anything that does not look like a URL becomes a search.
enum AddressParser {
    static let searchTemplate = "https://www.google.com/search?q="

    static func url(from raw: String) -> URL? {
        let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return nil }
        if text.contains("://"), let u = URL(string: text) { return u }
        let looksLikeHost = !text.contains(" ")
            && (text.contains(".") || text.hasPrefix("localhost"))
        if looksLikeHost, let u = URL(string: "https://" + text) { return u }
        let q = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? text
        return URL(string: searchTemplate + q)
    }
}
