import Foundation
import Testing
@testable import NhetrinhCore

/// P9-REMEMBER (D28): the item keeps what a session cookie needs to work again; dated cookies never go in.
struct CookieCodingTests {
    @Test(arguments: [(secure: false, httpOnly: false), (secure: true, httpOnly: true),
                      (secure: true, httpOnly: false)])
    func aCookieComesBackTheSame(secure: Bool, httpOnly: Bool) throws {
        let cookie = try #require(fakeCookie("s0", session: true, secure: secure, httpOnly: httpOnly))
        let back = try #require(SignIns.decode(try SignIns.encode([cookie])))
        let one = try #require(back.first)
        #expect(back.count == 1)
        #expect(one.name == "s0" && one.value == "fake-1" && one.domain == "example.test" && one.path == "/")
        #expect(one.isSecure == secure && one.isHTTPOnly == httpOnly && one.isSessionOnly)
    }

    @Test func noCookiesIsAnItemToo() throws {
        #expect(SignIns.decode(try SignIns.encode([]))?.isEmpty == true)
    }

    @Test(arguments: ["", "not json", "[]", "{\"version\": 99, \"cookies\": []}"])
    func aCorruptItemIsNil(text: String) {
        #expect(SignIns.decode(Data(text.utf8)) == nil)
    }

    @Test(arguments: [(session: 2, dated: 3), (session: 0, dated: 1), (session: 1, dated: 0)])
    func onlySessionCookiesAreKept(session: Int, dated: Int) {
        let kept = SignIns.sessionOnly(fakeCookies(session: session, dated: dated))
        #expect(kept.count == session && kept.allSatisfy(\.isSessionOnly))
    }
}
