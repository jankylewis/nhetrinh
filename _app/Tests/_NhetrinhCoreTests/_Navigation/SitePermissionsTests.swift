import Testing
@testable import NhetrinhCore

// P3 (hubs/product/plan/M2_REAL_SITES_WORK.md): camera and microphone are asked per site, and the
// answer is kept for that site until the app quits.

@Test(arguments: [MediaKind.camera, .microphone, .cameraAndMicrophone])
func nothingIsDecidedBeforeTheSiteAsks(kind: MediaKind) {
    #expect(SitePermissions().decision(site: "https://a.test:443", kind: kind) == nil)
}

/// The answer is kept for that site and that kind only.
@Test(arguments: [true, false])
func answerIsKeptPerSiteAndKind(allowed: Bool) {
    var permissions = SitePermissions()
    let site = SitePermissions.site(scheme: "https", host: "a.test", port: 0)
    permissions.record(allowed, site: site, kind: .microphone)
    #expect(permissions.decision(site: site, kind: .microphone) == allowed)
    #expect(permissions.decision(site: "https://b.test:443", kind: .microphone) == nil, "another site is asked")
    #expect(permissions.decision(site: site, kind: .camera) == nil, "another kind is asked again")
}

/// P3-REVIEW P1: a site is an origin. Another scheme or port of the same host is another site; the case
/// and a default port written out are the same site. Every `file:` page is one site ("file://:0").
@Test(arguments: [
    (("https", "a.test", 0), ("HTTPS", "A.Test", 443), true),
    (("http", "127.0.0.1", 8000), ("http", "127.0.0.1", 8000), true),
    (("http", "127.0.0.1", 8000), ("http", "127.0.0.1", 9000), false),
    (("http", "a.test", 0), ("https", "a.test", 0), false),
    (("https", "a.test", 0), ("https", "a.test", 8443), false),
    (("http", "a.test", 0), ("http", "a.test", 80), true),
] as [((String, String, Int), (String, String, Int), Bool)])
func aSiteIsAnOrigin(first: (String, String, Int), second: (String, String, Int), same: Bool) {
    let one = SitePermissions.site(scheme: first.0, host: first.1, port: first.2)
    let other = SitePermissions.site(scheme: second.0, host: second.1, port: second.2)
    var permissions = SitePermissions()
    permissions.record(true, site: one, kind: .camera)
    #expect((permissions.decision(site: other, kind: .camera) == true) == same, "\(one) then \(other)")
}

/// The question names the site and what it wants, in the user's words.
@Test(arguments: [
    ("127.0.0.1", MediaKind.microphone, "Allow 127.0.0.1 to use your microphone?"),
    ("a.test", .camera, "Allow a.test to use your camera?"),
    ("a.test", .cameraAndMicrophone, "Allow a.test to use your camera and microphone?"),
    ("", .camera, "Allow this page to use your camera?"),
])
func questionNamesTheSite(host: String, kind: MediaKind, text: String) {
    #expect(SitePermissions.question(host: host, kind: kind) == text)
}
