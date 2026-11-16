import Foundation

// P3 (hubs/product/plan/M2_REAL_SITES_WORK.md). STUB, red first (P3-PREP-1, DECISIONS.md D24):
// the type compiles, the behaviour is not built; the tests in ExternalSchemeTests.swift fail until P3.

/// Which links leave the browser: the app asks, then hands them to macOS (`mailto:`, `tel:`,
/// meeting apps, any custom scheme). `http`, `https`, `about`, `blob`, `data` and `file` stay.
public enum ExternalScheme {
    /// Whether a link with this scheme leaves the browser. Case does not matter; no scheme stays.
    public static func leaves(scheme: String?) -> Bool {
        false  // STUB
    }

    /// Whether `url` leaves the browser, by its scheme.
    public static func leaves(_ url: URL) -> Bool {
        leaves(scheme: url.scheme)
    }
}
