import Foundation

// P2 (hubs/product/plan/M1_DAILY_DRIVER.md); tests in FaviconURLTests.swift.

/// Where a page's icon is: its `<link rel="icon">`, else `/favicon.ico` on the page's own origin.
public enum FaviconURL {
    /// The icon URL for `page`, given the `href` of its `<link rel="icon">` (nil when it has none).
    /// A relative href resolves against the page; a `data:` href is the icon itself, kept as is;
    /// a missing or blank href, or one with another scheme, gives `/favicon.ico` of the page's origin.
    /// A page that is not http or https has no icon: nil.
    public static func resolve(href: String?, page: URL) -> URL? {
        guard let scheme = page.scheme?.lowercased(), ["http", "https"].contains(scheme) else { return nil }
        let text = href?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if text.lowercased().hasPrefix("data:") { return URL(string: text) }
        if !text.isEmpty, let icon = URL(string: text, relativeTo: page)?.absoluteURL,
           let iconScheme = icon.scheme?.lowercased(), ["http", "https"].contains(iconScheme) {
            return icon
        }
        return originIcon(of: page)
    }

    private static func originIcon(of page: URL) -> URL? {
        var parts = URLComponents()
        parts.scheme = page.scheme
        parts.host = page.host
        parts.port = page.port
        parts.path = "/favicon.ico"
        return parts.url
    }
}
