import WebKit

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
