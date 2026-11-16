import Foundation
import Testing
@testable import NhetrinhReadback

// P3 (hubs/product/plan/M2_REAL_SITES_WORK.md): the local pages of R19-R26, R26a and R26b.

@Test func pageBasicStepsAreR19ToR26() {
    #expect(BasicSteps.all.map(\.id) == ["R19", "R20", "R21", "R22", "R23", "R24", "R25", "R26", "R26a", "R26b"])
}

/// Each page holds the element the step clicks and the title the step reads.
@Test(arguments: [
    ("/dialogs", "id=\"alert\""), ("/dialogs", "id=\"confirm\""), ("/dialogs", "id=\"prompt\""),
    ("/upload", "type=\"file\" id=\"file\""), ("/mailto", "href=\"mailto:"), ("/media", "id=\"mic\""),
    ("/media", "id=\"camera\""), ("/fullscreen", "id=\"full\""),
])
func basicPageHasWhatTheStepClicks(path: String, part: String) {
    let reply = TestPageContent.reply(path: path)
    #expect(reply.status == "200 OK")
    #expect(String(decoding: reply.body, as: UTF8.self).contains(part))
}

private func basic(_ user: String, _ password: String) -> String {
    "Basic " + Data("\(user):\(password)".utf8).base64EncodedString()
}

/// The sign-in page: no or wrong credentials give 401 with a Basic challenge; the right ones the page.
@Test(arguments: [
    (nil, false), (basic(BasicPages.user, "wrong"), false), (basic("someone", BasicPages.password), false),
    (basic(BasicPages.user, BasicPages.password), true), ("Bearer x", false),
] as [(String?, Bool)])
func signInPageAsksForTheRightPassword(authorization: String?, signedIn: Bool) {
    let reply = TestPageContent.reply(path: "/auth", authorization: authorization)
    #expect(reply.status == (signedIn ? "200 OK" : "401 Unauthorized"))
    #expect(reply.headers.contains { $0.hasPrefix("WWW-Authenticate: Basic realm=") } == !signedIn)
    #expect(String(decoding: reply.body, as: UTF8.self).contains("<title>\(BasicPages.signedInTitle)</title>")
            == signedIn)
}

@Test(arguments: [("GET /auth HTTP/1.1\r\nAuthorization: Basic eA==\r\n\r\n", "Basic eA=="),
                  ("GET /auth HTTP/1.1\r\n\r\n", nil)])
func authorizationHeaderIsRead(head: String, value: String?) {
    #expect(TestPages.header("Authorization", in: head) == value)
}

/// R23: a port nobody listens on, then a server on that very port.
@Test func serverStartsOnAFreedPort() async throws {
    let port = try TestPages.freePort()
    let pages = try TestPages(port: port)
    #expect(pages.port == port)
    let url = try #require(URL(string: pages.url("/page/2")))
    let (body, _) = try await URLSession.shared.data(from: url)
    #expect(String(decoding: body, as: UTF8.self).contains("<title>nhetrinh test 2</title>"))
}
