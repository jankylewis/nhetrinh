import AppKit
import NhetrinhCore
import Testing
import WebKit
@testable import Nhetrinh

/// P9-REMEMBER guard (headmate rule): no unit test reaches the real Keychain or a real cookie store. Before a
/// launch the seams are in memory; the real Keychain seam is made only by `AppDelegate` at launch, and it
/// refuses with no Keychain call outside the app; so does the cookie store's (`noSeamInThisProcessCanReachAStore`).
@MainActor
struct SignInSeamTests {
    @Test func beforeALaunchTheSeamsAreInMemory() {
        #expect(SignInSeams.secrets is HeldSecrets)
        #expect(SignInSeams.jar() is HeldJar)
    }

    /// Defect 4 (REVIEW_P9_REMEMBER.md): in a test process both real seams refuse, whatever a test passes and
    /// in any order: neither can reach a store. The Keychain throws; the cookie store is never even asked for.
    @Test func noSeamInThisProcessCanReachAStore() throws {
        _ = SignInSeams.secrets
        #expect(KeychainSecrets.reachable == 0 && WebCookieJar.reachable == 0 && !SecurityCalls().reachesKeychain)
        #expect(throws: SecretsError.notLaunched) { try KeychainSecrets().read(service: "io.example.test") }
        var asked = false
        let jar = WebCookieJar { asked = true; return WKWebsiteDataStore.nonPersistent().httpCookieStore }
        var set = false, all: [HTTPCookie]? = nil
        let cookie = try #require(HTTPCookie(properties: [.name: "s0", .value: "fake-1", .domain: "example.test",
                                                          .path: "/"]))
        jar.set(cookie) { set = true }
        jar.all { all = $0 }
        #expect(!asked && set && all?.isEmpty == true)
        #expect(KeychainSecrets.reachable == 0 && WebCookieJar.reachable == 0)
    }

    @Test(arguments: [
        (bundleID: String?.none, allowed: false), (bundleID: "com.apple.dt.xctest.tool", allowed: false),
        (bundleID: "io.github.jankylewis.nhetrinh.other", allowed: false),
        (bundleID: "io.github.jankylewis.nhetrinh", allowed: true),
    ])
    func onlyTheAppReachesTheKeychain(bundleID: String?, allowed: Bool) {
        #expect(KeychainSecrets.allowed(bundleID) == allowed)
    }

    @Test func thisTestProcessIsNotTheApp() {
        #expect(!KeychainSecrets.allowed(Bundle.main.bundleIdentifier))
    }

    /// The launch's switch is read from `prefs.json` without moving a bad file (loadPrefs reports it later).
    @Test(arguments: [(text: String?.none, on: true), (text: "{\"rememberSignIns\": false}", on: false),
                      (text: "{\"rememberSignIns\": true}", on: true), (text: "not json", on: true)])
    func theLaunchReadsTheSwitch(text: String?, on: Bool) throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("remember-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let file = folder.appendingPathComponent(PrefsStore.fileName)
        if let text { try Data(text.utf8).write(to: file) }
        #expect(BrowserWindowController.remembers(in: folder) == on)
        #expect(FileManager.default.fileExists(atPath: file.path) == (text != nil))
    }

    @Test func aMeasurementRunHasNoKeeper() {
        #expect(BrowserWindowController.signInKeeper(folder: nil, profile: nil) == nil)
    }
}
