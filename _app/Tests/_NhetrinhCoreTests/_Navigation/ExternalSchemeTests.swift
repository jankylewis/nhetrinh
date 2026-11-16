import Foundation
import Testing
@testable import NhetrinhCore

// P3 tests (hubs/product/plan/M2_REAL_SITES_WORK.md), red first (P3-PREP-1, DECISIONS.md D24):
// `ExternalScheme.leaves` is a stub, so every case here fails until P3 builds it.

/// Every case is checked beside a control of the other kind (`https` stays, `mailto` leaves), so a
/// policy that answers the same for every scheme fails every case.
private func expectDecision(_ scheme: String?, leaves: Bool) {
    #expect(ExternalScheme.leaves(scheme: scheme) == leaves)
    #expect(ExternalScheme.leaves(scheme: leaves ? "https" : "mailto") == !leaves, "the control")
}

/// The web's own schemes stay in the browser, whatever their case.
@Test(arguments: ["http", "https", "about", "blob", "data", "file", "HTTPS", "Http", "ABOUT", "Blob", "DATA", "File"])
func webSchemesStay(scheme: String) {
    expectDecision(scheme, leaves: false)
}

/// Mail, phone, meeting apps and any other app's scheme leave, whatever their case.
@Test(arguments: ["mailto", "tel", "zoommtg", "msteams", "slack", "x-myapp", "MAILTO", "Tel", "ZoomMtg"])
func otherSchemesLeave(scheme: String) {
    expectDecision(scheme, leaves: true)
}

/// No scheme at all is not a link to another app: it stays.
@Test(arguments: [nil, "", " "] as [String?])
func noSchemeStays(scheme: String?) {
    expectDecision(scheme, leaves: false)
}

/// Whole links, read by their scheme.
@Test(arguments: [
    ("https://example.com/", false), ("about:blank", false), ("blob:https://example.com/0b1c", false),
    ("data:text/plain,hi", false), ("file:///tmp/a.html", false), ("mailto:someone@example.com", true),
    ("tel:+15550100", true), ("zoommtg://zoom.us/join?confno=1", true), ("MailTo:someone@example.com", true),
])
func linksAreReadByTheirScheme(link: String, leaves: Bool) throws {
    let url = try #require(URL(string: link))
    #expect(ExternalScheme.leaves(url) == leaves)
    #expect(ExternalScheme.leaves(scheme: leaves ? "https" : "mailto") == !leaves, "the control")
}
