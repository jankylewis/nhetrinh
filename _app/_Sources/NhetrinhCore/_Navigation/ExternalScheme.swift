import Foundation

// P3 (hubs/product/plan/M2_REAL_SITES_WORK.md); tests in ExternalSchemeTests.swift.

/// Which links leave the browser: the app asks, then hands them to macOS (`mailto:`, `tel:`,
/// meeting apps, any custom scheme). `http`, `https`, `about`, `blob`, `data` and `file` stay.
public enum ExternalScheme {
    static let staying: Set<String> = ["http", "https", "about", "blob", "data", "file"]

    /// Whether a link with this scheme leaves the browser. Case does not matter; no scheme stays.
    public static func leaves(scheme: String?) -> Bool {
        let name = (scheme ?? "").trimmingCharacters(in: .whitespaces).lowercased()
        return !name.isEmpty && !staying.contains(name)
    }

    /// Whether `url` leaves the browser, by its scheme.
    public static func leaves(_ url: URL) -> Bool {
        leaves(scheme: url.scheme)
    }
}
