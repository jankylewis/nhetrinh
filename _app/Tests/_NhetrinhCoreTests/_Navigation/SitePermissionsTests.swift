import Testing
@testable import NhetrinhCore

// P3 (hubs/product/plan/M2_REAL_SITES_WORK.md): camera and microphone are asked per site, and the
// answer is kept for that site until the app quits.

@Test(arguments: [MediaKind.camera, .microphone, .cameraAndMicrophone])
func nothingIsDecidedBeforeTheSiteAsks(kind: MediaKind) {
    #expect(SitePermissions().decision(host: "a.test", kind: kind) == nil)
}

/// The answer is kept for that site and that kind only; the host's case does not matter.
@Test(arguments: [true, false])
func answerIsKeptPerSiteAndKind(allowed: Bool) {
    var permissions = SitePermissions()
    permissions.record(allowed, host: "A.test", kind: .microphone)
    #expect(permissions.decision(host: "a.TEST", kind: .microphone) == allowed)
    #expect(permissions.decision(host: "b.test", kind: .microphone) == nil, "another site is asked again")
    #expect(permissions.decision(host: "a.test", kind: .camera) == nil, "another kind is asked again")
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
