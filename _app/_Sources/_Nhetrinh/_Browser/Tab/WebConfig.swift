import NhetrinhCore
import WebKit

/// One configuration for every tab: shared cookies, cache and process policy.
enum WebConfig {
    static let shared: WKWebViewConfiguration = {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = dataStore()
        // A Safari-like user agent tail, so sites treat nhetrinh as Safari.
        config.applicationNameForUserAgent = "Version/18.0 Safari/605.1.15"
        return config
    }()

    /// NHT_PROFILE=<name> selects a separate profile. The readback runs in the profile "readback",
    /// so a test run never reads or writes the cookies and cache of the user's real browsing.
    private static func dataStore() -> WKWebsiteDataStore {
        guard let name = ProcessInfo.processInfo.environment["NHT_PROFILE"], !name.isEmpty else {
            return .default()
        }
        if #available(macOS 14.0, *) {
            return WKWebsiteDataStore(forIdentifier: Profile.identifier(for: name))
        }
        return .nonPersistent()
    }
}
