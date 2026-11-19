import Foundation
import Testing
@testable import NhetrinhCore

/// P11-HISTORY (D30): only a finished http or https page is kept; never about:, data:, file:, the error page,
/// or the readback's own pages (loopback, probe on) outside the readback profile; nothing with the switch off.
struct HistoryRulesTests {
    @Test(arguments: [
        (url: "https://example.test/", kept: true), (url: "http://example.test/a?b=c", kept: true),
        (url: "HTTPS://EXAMPLE.TEST/", kept: true), (url: "about:blank", kept: false),
        (url: "data:text/html,hi", kept: false), (url: "file:///tmp/a.html", kept: false),
        (url: "ftp://example.test/", kept: false), (url: "https:///nohost", kept: false),
        (url: "http://127.0.0.1:8080/", kept: true), (url: "http://localhost:3000/", kept: true),
    ])
    func whichPagesAreKept(url: String, kept: Bool) {
        let rules = HistoryRules(remember: true, probeOn: false, profile: nil)
        #expect(rules.records(URL(string: url), errorPage: false) == kept)
    }

    @Test func theErrorPageAndNoAddressAreNeverKept() {
        let rules = HistoryRules(remember: true, probeOn: false, profile: nil)
        #expect(!rules.records(URL(string: "https://example.test/"), errorPage: true))
        #expect(!rules.records(nil, errorPage: false))
    }

    @Test(arguments: [
        "https://example.test/", "http://127.0.0.1:8080/", "http://localhost/",
    ])
    func theSwitchOffKeepsNothing(url: String) {
        for profile in [nil, "readback"] as [String?] {
            let rules = HistoryRules(remember: false, probeOn: true, profile: profile)
            #expect(!rules.records(URL(string: url), errorPage: false))
        }
    }

    /// The readback's pages (127.0.0.1, with the probe on) are kept only in the readback profile (R54).
    @Test(arguments: [
        (url: "http://127.0.0.1:5000/page/1", probe: true, profile: nil, kept: false),
        (url: "http://localhost:5000/page/1", probe: true, profile: "work", kept: false),
        (url: "http://[::1]:5000/", probe: true, profile: nil, kept: false),
        (url: "http://127.0.0.1:5000/page/1", probe: true, profile: "readback", kept: true),
        (url: "http://127.0.0.1:5000/page/1", probe: false, profile: nil, kept: true),
        (url: "https://example.test/", probe: true, profile: nil, kept: true),
    ] as [(url: String, probe: Bool, profile: String?, kept: Bool)])
    func theReadbackPages(url: String, probe: Bool, profile: String?, kept: Bool) {
        let rules = HistoryRules(remember: true, probeOn: probe, profile: profile)
        #expect(rules.records(URL(string: url), errorPage: false) == kept)
    }

    @Test func theRememberHistorySwitchIsOnByDefaultAndKept() throws {
        #expect(Prefs().rememberHistory)
        #expect(Prefs.decode(Data("{}".utf8))?.rememberHistory == true)
        #expect(Prefs.decode(Data("{\"rememberHistory\": 0}".utf8))?.rememberHistory == true)
        var prefs = Prefs()
        prefs.rememberHistory = false
        #expect(Prefs.decode(try prefs.encoded())?.rememberHistory == false)
        prefs.forgetSites()
        #expect(prefs.rememberHistory == false)
    }

    /// A sign-in step is never kept (headmate, 2026-11-19: the dropdown offered identity-provider pages): a URL
    /// carrying a token or a SAML message, an authorize request (client_id with redirect_uri or response_type), or
    /// a callback (code with state), in the query or the fragment, any case. A page with only one of a pair stays.
    @Test(arguments: [
        (url: "https://id.example.test/authorize?client_id=a&redirect_uri=https%3A%2F%2Fb.test", kept: false),
        (url: "https://id.example.test/oauth2/v1/authorize?client_id=a&response_type=code", kept: false),
        (url: "https://app.example.test/callback?code=x&state=y", kept: false),
        (url: "https://app.example.test/#id_token=x&state=y", kept: false),
        (url: "https://app.example.test/#Access_Token=x", kept: false),
        (url: "https://sso.example.test/saml?SAMLRequest=x", kept: false),
        (url: "https://app.example.test/acs?samlresponse=x", kept: false),
        (url: "https://app.example.test/?refresh_token=x", kept: false),
        (url: "https://code.example.test/search?code=swift", kept: true),
        (url: "https://app.example.test/settings?state=open", kept: true),
        (url: "https://docs.example.test/oauth?client_id=a", kept: true),
    ])
    func signInStepsAreNeverKept(url: String, kept: Bool) {
        let rules = HistoryRules(remember: true, probeOn: false, profile: nil)
        #expect(rules.records(URL(string: url), errorPage: false) == kept)
    }
}
