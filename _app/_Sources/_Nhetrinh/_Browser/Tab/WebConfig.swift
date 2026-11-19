import NhetrinhCore
import WebKit

/// One configuration for every tab: shared cookies, cache and process policy.
enum WebConfig {
    static let shared: WKWebViewConfiguration = {
        let config = WKWebViewConfiguration()
        let layout = BrowserWindowController.profileLayout(ProcessInfo.processInfo.environment)
        config.websiteDataStore = choose(layout?.webStore, standard: { .default() }, none: { .nonPersistent() },
                                         identified: identified)
        // A Safari-like user agent tail, so sites treat nhetrinh as Safari.
        config.applicationNameForUserAgent = "Version/18.0 Safari/605.1.15"
        config.preferences.isElementFullscreenEnabled = true  // fullscreen video (P3)
        return config
    }()

    /// P10-PROFILE (D29), HARD RULE: `Default` (no NHT_PROFILE) keeps WebKit's default store, where every cookie
    /// and sign-in of the headmate is; another profile its own (`readback`: never the user's). A refused name
    /// (`ProfileLayout.refusal`) keeps nothing. Generic, so a test checks the choice without making a store.
    static func choose<Store>(_ store: WebStore?, standard: () -> Store, none: () -> Store,
                              identified: (UUID) -> Store) -> Store {
        switch store {
        case .standard: return standard()
        case .identifier(let id): return identified(id)
        case nil: return none()
        }
    }

    private static func identified(_ id: UUID) -> WKWebsiteDataStore {
        if #available(macOS 14.0, *) { return WKWebsiteDataStore(forIdentifier: id) }
        return .nonPersistent()
    }
}
