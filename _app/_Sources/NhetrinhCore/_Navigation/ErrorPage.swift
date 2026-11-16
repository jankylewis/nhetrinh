import Foundation

// P3 (hubs/product/plan/M2_REAL_SITES_WORK.md). STUB, red first (P3-PREP-1, DECISIONS.md D24):
// the type compiles, the behaviour is not built; the tests in ErrorPageTests.swift fail until P3.

/// The page a tab shows when a load fails: the reason in plain words and a Retry button.
/// Never the raw error (its domain, code or system text) and never unescaped page input.
public enum ErrorPage {
    /// The page for `error`, a load failure as WebKit reports it (`NSURLErrorDomain` codes).
    /// The failing address comes from `NSURLErrorFailingURLErrorKey`, else `NSURLErrorFailingURLStringErrorKey`;
    /// it is shown as escaped text, and Retry loads it again.
    public static func html(for error: NSError) -> String {
        ""  // STUB
    }
}
