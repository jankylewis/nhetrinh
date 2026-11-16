import Foundation
import Testing
@testable import NhetrinhCore

// P3 (hubs/product/plan/M2_REAL_SITES_WORK.md): which failures show the error page, the page's
// title, and the address Retry loads. The reasons and their words are in _ErrorPageTests.swift.

/// A load the user or the app ended is not an error: Stop (R18), a new address typed during a load,
/// a link handed to another app (WebKit 102), a page handled by a plug-in (WebKit 204).
@Test(arguments: [
    (NSURLErrorDomain, NSURLErrorCancelled, false), ("WebKitErrorDomain", 102, false),
    ("WebKitErrorDomain", 204, false), (NSURLErrorDomain, NSURLErrorTimedOut, true),
    (NSURLErrorDomain, NSURLErrorCannotConnectToHost, true), (NSURLErrorDomain, NSURLErrorCannotFindHost, true),
    ("WebKitErrorDomain", 101, true), (NSURLErrorDomain, 102, true),
])
func onlyRealFailuresShowThePage(domain: String, code: Int, shows: Bool) {
    #expect(ErrorPage.shows(NSError(domain: domain, code: code)) == shows)
}

/// The window and the sidebar row read the reason: the page's title is its headline.
@Test(arguments: failureCases)
func errorPageTitleIsTheReason(run: FailureCase) {
    let error = NSError(domain: run.domain, code: run.code)
    #expect(ErrorPage.title(for: error) == run.reason.rawValue)
    #expect(ErrorPage.html(for: error).contains("<title>\(run.reason.rawValue)</title>"))
}

/// Retry loads the failing address: the URL key first, else the string key; none gives nil.
@Test(arguments: [
    ([NSURLErrorFailingURLErrorKey: URL(string: "https://a.test/x") as Any], "https://a.test/x"),
    ([NSURLErrorFailingURLStringErrorKey: "https://b.test/y"], "https://b.test/y"),
    ([NSURLErrorFailingURLErrorKey: URL(string: "https://a.test/") as Any,
      NSURLErrorFailingURLStringErrorKey: "https://b.test/"], "https://a.test/"),
    ([:], nil),
] as [([String: Any], String?)])
func failingAddressIsRead(info: [String: Any], address: String?) {
    let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut, userInfo: info)
    #expect(ErrorPage.failingURL(of: error)?.absoluteString == address)
}

/// Retry carries the address as an escaped attribute and loads it; with no address it reloads.
@Test(arguments: [true, false])
func retryLoadsTheAddress(hasAddress: Bool) {
    let info: [String: Any] = hasAddress ? [NSURLErrorFailingURLStringErrorKey: "https://a.test/?q='x'&y=1"] : [:]
    let html = ErrorPage.html(for: NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut, userInfo: info))
    #expect(html.contains("data-url=\"https://a.test/?q=&#39;x&#39;&amp;y=1\"") == hasAddress)
    #expect(html.contains("location.reload()") == !hasAddress)
}
