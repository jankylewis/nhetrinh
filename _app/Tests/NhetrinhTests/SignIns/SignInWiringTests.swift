import AppKit
import NhetrinhCore
import Testing
@testable import Nhetrinh

/// P9-REMEMBER wiring, on in-memory seams and a temporary folder only (synthetic cookies: example.test,
/// fake-1): the launch opens the tabs once, after the cookies are set or after the wait; a quit keeps them;
/// the Settings Hub's switch and Clear All delete the kept item. The hub's data store is a non-persistent one.
@MainActor
struct SignInWiringTests {
    /// A jar that never answers, as a WebKit that hangs.
    final class SilentJar: CookieJar {
        func all(_ done: @escaping ([HTTPCookie]) -> Void) {}
        func set(_ cookie: HTTPCookie, _ done: @escaping () -> Void) {}
    }

    let secrets = HeldSecrets()
    let jar = HeldJar()
    let service = SignIns.service(profile: "wiring")

    private func keeper(_ jar: CookieJar? = nil) throws -> SignInKeeper {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("wiring-\(UUID().uuidString)")
        return SignInKeeper(secrets: secrets, jar: jar ?? self.jar, marker: CleanQuitMarker(folder: folder),
                            service: service) { _ in }
    }

    private func sessionCookies(_ count: Int) -> [HTTPCookie] {
        (0..<count).compactMap { HTTPCookie(properties: [.name: "s\($0)", .value: "fake-1", .domain: "example.test",
                                                         .path: "/"]) }
    }

    private func browser() -> BrowserWindowController {
        _ = NSApplication.shared
        return BrowserWindowController()
    }

    @Test(arguments: [0, 2])
    func theLaunchOpensTheTabsOnceAfterTheCookies(kept: Int) throws {
        if kept > 0 { secrets.items[service] = try SignIns.encode(sessionCookies(kept)) }
        let browser = browser()
        var opened = 0
        browser.restoreSignIns(with: try keeper(), remember: true) { opened += 1 }
        #expect(opened == 1 && jar.cookies.count == kept && secrets.items.isEmpty)
        #expect(browser.signIns != nil)
    }

    @Test func noKeeperOpensTheTabsAtOnce() {
        var opened = 0
        browser().restoreSignIns(with: nil, remember: true) { opened += 1 }
        #expect(opened == 1)
    }

    @Test func aHangingWebKitStillOpensTheTabs() async throws {
        secrets.items[service] = try SignIns.encode(sessionCookies(1))
        var opened = 0
        browser().restoreSignIns(with: try keeper(SilentJar()), remember: true, wait: 0.05) { opened += 1 }
        #expect(opened == 0)
        try await Task.sleep(nanoseconds: 300_000_000)
        #expect(opened == 1)
    }

    @Test(arguments: [true, false])
    func aQuitKeepsTheSessionCookiesWhenOn(on: Bool) throws {
        let browser = browser()
        browser.restoreSignIns(with: try keeper(), remember: true) {}
        browser.prefs.rememberSignIns = on
        jar.cookies = sessionCookies(3)
        var ended = 0
        browser.keepSignIns { ended += 1 }
        #expect(ended == 1)
        #expect(secrets.items[service].flatMap(SignIns.decode)?.count == (on ? 3 : nil))
    }

    private func hubbed() throws -> (BrowserWindowController, SettingsHub) {
        let browser = browser()
        browser.restoreSignIns(with: try keeper(), remember: true) {}
        let hub = SettingsHub(store: .nonPersistent())
        browser.wire(hub)
        secrets.items[service] = Data("kept".utf8)
        return (browser, hub)
    }

    @Test func theSwitchShowsOnAndOffDeletesTheItem() throws {
        let (browser, hub) = try hubbed()
        #expect(hub.remember.state == .on)
        #expect(hub.set(SettingsHub.rememberTitle, to: "maybe") == false)
        #expect(hub.set(SettingsHub.rememberTitle, to: "off"))
        #expect(browser.prefs.rememberSignIns == false && secrets.items.isEmpty)
        #expect(hub.set(SettingsHub.rememberTitle, to: "on"))
        #expect(browser.prefs.rememberSignIns && hub.remember.state == .on)
    }

    @Test(arguments: [(range: ClearRange.all, kept: false), (range: ClearRange.lastHour, kept: true)])
    func clearAllDeletesTheItem(range: ClearRange, kept: Bool) throws {
        let (_, hub) = try hubbed()
        hub.clear(range)
        #expect((secrets.items[service] != nil) == kept)
    }

    /// Defect 5 (REVIEW_P9_REMEMBER.md): Quit while the kept cookies are still being set (no window yet): the
    /// quit goes through the launching window, the marker is cleared and the item stays for the next launch.
    /// The restore never ends here (wait 3600 s), so the tabs never open and no real session is read.
    @Test func aQuitBeforeTheRestoreEndsIsCleanAndKeepsTheItem() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("wiring-\(UUID().uuidString)")
        let marker = CleanQuitMarker(folder: folder)
        secrets.items[service] = try SignIns.encode(sessionCookies(2))
        let keeper = SignInKeeper(secrets: secrets, jar: SilentJar(), marker: marker, service: service) { _ in }
        let delegate = AppDelegate()
        delegate.begin(browser(), keeper: keeper, remember: true, env: [:], wait: 3600)
        #expect(FileManager.default.fileExists(atPath: marker.file.path))
        #expect(delegate.quitTarget?.signIns != nil)
        delegate.applicationWillTerminate(Notification(name: NSApplication.willTerminateNotification))
        #expect(!FileManager.default.fileExists(atPath: marker.file.path))
        #expect(secrets.items[service] != nil)
    }
}
