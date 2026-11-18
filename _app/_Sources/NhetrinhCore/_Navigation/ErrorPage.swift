import Foundation

// P3 (hubs/product/plan/M2_REAL_SITES_WORK.md); tests in ErrorPage/_ErrorPageTests.swift and ErrorPageShownTests.swift.

/// The page a tab shows when a load fails: the reason in plain words and a Retry button.
/// Never the raw error (its domain, code or system text) and never unescaped page input.
public enum ErrorPage {
    /// Whether `error` shows the page. A load the user or the app ended is not a failure: Stop or a new
    /// address (cancelled), a link handed to another app (WebKit 102), a plug-in's page (WebKit 204).
    public static func shows(_ error: NSError) -> Bool {
        switch (error.domain, error.code) {
        case (NSURLErrorDomain, NSURLErrorCancelled), ("WebKitErrorDomain", 102), ("WebKitErrorDomain", 204):
            return false
        default: return true
        }
    }

    /// The reason's headline: the page's title, so the window and the sidebar row read it too.
    public static func title(for error: NSError) -> String {
        guard error.domain == NSURLErrorDomain else { return "This page could not be loaded" }
        switch error.code {
        case NSURLErrorNotConnectedToInternet, NSURLErrorNetworkConnectionLost, NSURLErrorDataNotAllowed:
            return "You are not connected to the internet"
        case NSURLErrorCannotFindHost, NSURLErrorDNSLookupFailed: return "No site has this name"
        case NSURLErrorTimedOut: return "The site took too long to answer"
        case NSURLErrorAppTransportSecurityRequiresSecureConnection:  // NT-BUG-019: refused by ATS, never sent
            return "This site needs a secure connection"
        case NSURLErrorSecureConnectionFailed, NSURLErrorServerCertificateHasBadDate,
             NSURLErrorServerCertificateUntrusted, NSURLErrorServerCertificateHasUnknownRoot,
             NSURLErrorServerCertificateNotYetValid, NSURLErrorClientCertificateRejected:
            return "The certificate of this site is not valid"
        default: return "This page could not be loaded"
        }
    }

    /// The address that failed: `NSURLErrorFailingURLErrorKey`, else `NSURLErrorFailingURLStringErrorKey`.
    public static func failingURL(of error: NSError) -> URL? {
        address(of: error).flatMap(URL.init(string:))
    }

    /// The failing address as WebKit gave it, never re-encoded: the page shows it as it was asked for.
    static func address(of error: NSError) -> String? {
        (error.userInfo[NSURLErrorFailingURLErrorKey] as? URL)?.absoluteString
            ?? error.userInfo[NSURLErrorFailingURLStringErrorKey] as? String
    }

    /// The page for `error`, a load failure as WebKit reports it (`NSURLErrorDomain` codes).
    /// The failing address is shown as escaped text, and Retry loads it again (no address: reload).
    /// A bad certificate has no "proceed anyway" (DECISIONS.md Q5).
    public static func html(for error: NSError) -> String {
        let title = escaped(title(for: error))
        let address = Self.address(of: error).map(escaped)
        let retry = address.map { "data-url=\"\($0)\" onclick=\"location.assign(this.dataset.url)\"" }
            ?? "onclick=\"location.reload()\""
        return """
            <!doctype html><meta charset="utf-8"><title>\(title)</title>
            <style>body{font:15px -apple-system,sans-serif;color:#333;margin:15vh auto;max-width:36em;padding:0 2em}
            h1{font-size:22px}p{color:#777;word-break:break-all}
            @media (prefers-color-scheme:dark){body{background:#222;color:#ddd}}</style>
            <h1>\(title)</h1><p>\(address ?? "")</p><button id="retry" \(retry)>Retry</button>
            """
    }

    static func escaped(_ text: String) -> String {
        text.replacingOccurrences(of: "&", with: "&amp;").replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;").replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
    }
}
