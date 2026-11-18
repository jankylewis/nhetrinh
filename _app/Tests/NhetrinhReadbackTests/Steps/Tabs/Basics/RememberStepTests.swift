import Foundation
import Testing
@testable import NhetrinhReadback

/// R51 (P9-REMEMBER): its pages set a session cookie (no expiry, so WebKit never writes it to disk) and read
/// it back; its verdict: on, the cookie is back; off, it is gone. R51 itself is not run here.
struct RememberStepTests {
    @Test func theSetPageMakesASessionCookie() throws {
        let page = try #require(ToolPages.reply(path: "/cookie/session")).body
        let text = String(decoding: page, as: UTF8.self)
        #expect(text.contains("document.cookie = 'nhetrinh_signin=readback; path=/'"))
        #expect(!text.contains("max-age") && !text.contains("expires"))
        #expect(text.contains("'\(ToolPages.sessionSetTitle)'"))
    }

    @Test func theReadPageNamesTheCookie() throws {
        let page = try #require(ToolPages.reply(path: "/cookie/session/read")).body
        #expect(String(decoding: page, as: UTF8.self).contains("includes('nhetrinh_signin=readback')"))
    }

    @Test(arguments: [
        (on: true, seen: "session: readback", fails: false), (on: true, seen: "session: none", fails: true),
        (on: false, seen: "session: none", fails: false), (on: false, seen: "session: readback", fails: true),
        (on: true, seen: "", fails: true), (on: false, seen: "session: set", fails: true),
    ])
    func theVerdict(on: Bool, seen: String, fails: Bool) {
        #expect((RememberStep.failure(switchOn: on, seen: seen) != nil) == fails)
    }

    @Test func theStepIsR51AndNamesTheHubSwitch() {
        #expect(RememberStep.step.id == "R51")
        #expect(RememberStep.title == "Remember sign-ins after quit")
    }

    /// Defect 3 (REVIEW_P9_REMEMBER.md): the line claims only what the step read: no count it never read.
    @Test func theLineClaimsNoCount() {
        #expect(!RememberStep.passLine.contains("kept"))
        #expect(RememberStep.passLine.contains("the page read it"))
    }
}
