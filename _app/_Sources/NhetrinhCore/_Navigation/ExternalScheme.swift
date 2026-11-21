import Foundation

// P3 (hubs/product/plan/M2_REAL_SITES_WORK.md); tests in ExternalSchemeTests.swift.

/// Which links leave the browser: the app asks, then hands them to macOS (`mailto:`, `tel:`,
/// meeting apps, any custom scheme). `http`, `https`, `about`, `blob`, `data` and `file` stay, and so does
/// `javascript`: it runs in its own page, never in another app (P2's ⌘-click lets it run there).
public enum ExternalScheme {
    static let staying: Set<String> = ["http", "https", "about", "blob", "data", "file", "javascript"]

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

/// NT-BUG-026: a link macOS hands in (another app, an HTML file from Finder, a page from Handoff). The Info.plist
/// claims (`_build.sh`) and this rule are one list: web pages and local files.
public enum IncomingLink {
    static let schemes: Set<String> = ["http", "https", "file"]

    /// Whether `url` opens as a tab: a web page or a local file; any other scheme was never ours.
    public static func opens(_ url: URL) -> Bool { schemes.contains(url.scheme?.lowercased() ?? "") }

    /// The folder a local page may read (its pictures and styles), nothing above it; nil for a web page.
    public static func readAccess(for url: URL) -> URL? { url.isFileURL ? url.deletingLastPathComponent() : nil }
}
