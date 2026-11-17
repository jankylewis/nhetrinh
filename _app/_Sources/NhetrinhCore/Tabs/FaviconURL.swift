import Foundation

// P2 (hubs/product/plan/M1_DAILY_DRIVER.md); tests in FaviconURLTests.swift.

/// Where a page's icon is: its `<link rel="icon">`, else `/favicon.ico` on the page's own origin.
public enum FaviconURL {
    /// The longest `data:` href taken as an icon, in bytes; a longer one gives no icon. The app keys
    /// 2 x 200 cache entries by the icon URL: 400 x 4 KB is 1.6 MB at the very worst (NT-PRF-004).
    public static let largestDataHref = 4 * 1024

    /// The icon URL for `page`, given the `href` of its `<link rel="icon">` (nil when it has none).
    /// A relative href resolves against the page; a `data:` href is the icon itself (4 KB at most);
    /// a missing or blank href, or one with another scheme, gives `/favicon.ico` of the page's origin.
    /// A page that is not http or https has no icon: nil.
    public static func resolve(href: String?, page: URL) -> URL? {
        guard let scheme = page.scheme?.lowercased(), ["http", "https"].contains(scheme) else { return nil }
        let text = href?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if text.lowercased().hasPrefix("data:") {  // the URL is a cache key: kept small (NT-PRF-004)
            return text.utf8.count <= largestDataHref ? URL(string: text) : nil
        }
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
