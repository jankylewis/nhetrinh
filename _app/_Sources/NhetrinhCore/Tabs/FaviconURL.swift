import Foundation

// P2 (hubs/product/plan/M1_DAILY_DRIVER.md). STUB, red first (P2-PREP-1, DECISIONS.md D24):
// the types compile, the behaviour is not built; the tests in FaviconURLTests.swift fail until P2.

/// Where a page's icon is: its `<link rel="icon">`, else `/favicon.ico` on the page's own origin.
public enum FaviconURL {
    /// The icon URL for `page`, given the `href` of its `<link rel="icon">` (nil when it has none).
    /// A relative href resolves against the page; a `data:` href is the icon itself, kept as is;
    /// a missing or blank href, or one with another scheme, gives `/favicon.ico` of the page's origin.
    /// A page that is not http or https has no icon: nil.
    public static func resolve(href: String?, page: URL) -> URL? {
        page  // STUB
    }
}
