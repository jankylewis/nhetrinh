import Foundation
import Testing
@testable import NhetrinhCore

// P3 tests (hubs/product/plan/M2_REAL_SITES_WORK.md), red first (P3-PREP-1, DECISIONS.md D24):
// `ErrorPage.html(for:)` is a stub, so every test here fails until P3 builds it.

/// The headline of each reason: the words the user reads. Each page shows its own and no other.
enum Reason: String, CaseIterable {
    case offline = "You are not connected to the internet"
    case nameNotFound = "No site has this name"
    case certificate = "The certificate of this site is not valid"
    case timeout = "The site took too long to answer"
    case unknown = "This page could not be loaded"
}

struct FailureCase: CustomTestStringConvertible {
    let domain: String
    let code: Int
    let reason: Reason

    var testDescription: String { "\(domain) \(code): \(reason)" }
}

let failureCases = [
    FailureCase(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet, reason: .offline),
    FailureCase(domain: NSURLErrorDomain, code: NSURLErrorCannotFindHost, reason: .nameNotFound),
    FailureCase(domain: NSURLErrorDomain, code: NSURLErrorDNSLookupFailed, reason: .nameNotFound),
    FailureCase(domain: NSURLErrorDomain, code: NSURLErrorServerCertificateUntrusted, reason: .certificate),
    FailureCase(domain: NSURLErrorDomain, code: NSURLErrorServerCertificateHasBadDate, reason: .certificate),
    FailureCase(domain: NSURLErrorDomain, code: NSURLErrorServerCertificateHasUnknownRoot, reason: .certificate),
    FailureCase(domain: NSURLErrorDomain, code: NSURLErrorSecureConnectionFailed, reason: .certificate),
    FailureCase(domain: NSURLErrorDomain, code: NSURLErrorTimedOut, reason: .timeout),
    FailureCase(domain: NSURLErrorDomain, code: 12_345, reason: .unknown),
    FailureCase(domain: "WebKitErrorDomain", code: NSURLErrorTimedOut, reason: .unknown),
]

/// System text that must never reach the page.
private let rawText = "RAW-SYSTEM-TEXT-0x2a"
private let failingURL = "https://example.test/path?q=<script>alert(1)</script>"

private func failure(_ run: FailureCase) -> NSError {
    NSError(domain: run.domain, code: run.code, userInfo: [
        NSLocalizedDescriptionKey: rawText,
        NSURLErrorFailingURLStringErrorKey: failingURL,
    ])
}

/// The right words for the reason, and no other reason's words.
@Test(arguments: failureCases)
func errorPageSaysTheReason(run: FailureCase) {
    let html = ErrorPage.html(for: failure(run))
    #expect(html.contains(run.reason.rawValue))
    for other in Reason.allCases where other != run.reason {
        #expect(!html.contains(other.rawValue), "the page also says \"\(other.rawValue)\"")
    }
}

/// Every error page has a Retry button.
@Test(arguments: failureCases)
func errorPageHasRetry(run: FailureCase) {
    let html = ErrorPage.html(for: failure(run))
    #expect(html.range(of: #"<button[^>]*>\s*Retry\s*</button>"#, options: .regularExpression) != nil)
}

/// The raw error never leaks: not its system text, its domain or its code.
@Test(arguments: failureCases)
func errorPageLeaksNoRawError(run: FailureCase) {
    let html = ErrorPage.html(for: failure(run))
    #expect(!html.isEmpty)
    #expect(!html.contains(rawText) && !html.contains(run.domain) && !html.contains("\(run.code)"))
}

/// The failing address is shown as text: a page cannot inject markup through its own address.
@Test(arguments: [Reason.offline, .unknown])
func errorPageEscapesTheAddress(reason: Reason) throws {
    let run = try #require(failureCases.first { $0.reason == reason })
    let html = ErrorPage.html(for: failure(run))
    #expect(!html.contains("<script>alert(1)"))
    #expect(html.contains("&lt;script&gt;alert(1)&lt;/script&gt;"))
}
