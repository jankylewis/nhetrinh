import Foundation
import Testing
@testable import NhetrinhCore

/// P9-REMEMBER (D28): a quit keeps only session cookies as one item; a launch after a clean quit sets them
/// back and deletes the item; after a crash, with the switch off, or with a bad item nothing comes back and
/// the launch goes on. Every log line holds counts or an error kind only.
struct SignInKeeperTests {
    @Test(arguments: [(session: 2, dated: 1), (session: 0, dated: 3), (session: 3, dated: 0)])
    func quitKeepsOnlySessionCookies(session: Int, dated: Int) throws {
        let rig = try Rig()
        rig.jar.cookies = fakeCookies(session: session, dated: dated)
        #expect(rig.count { rig.keeper().quit(remember: true, done: $0) } == session)
        let kept = rig.item.flatMap(SignIns.decode) ?? []
        #expect(Set(kept.map(\.name)) == Set((0..<session).map { "s\($0)" }))
        #expect((rig.item != nil) == (session > 0))
    }

    @Test func quitWithTheSwitchOffWritesNothingAndDeletes() throws {
        let rig = try Rig()
        rig.secrets.items[rig.service] = try SignIns.encode(fakeCookies(session: 1, dated: 0))
        rig.jar.cookies = fakeCookies(session: 2, dated: 0)
        #expect(rig.count { rig.keeper().quit(remember: false, done: $0) } == 0)
        #expect(rig.secrets.items.isEmpty)
    }

    @Test(arguments: [1, 4])
    func launchAfterACleanQuitRestoresThenDeletes(count: Int) throws {
        let rig = try Rig()
        rig.jar.cookies = fakeCookies(session: count, dated: 1)
        let first = rig.keeper()
        _ = rig.count { first.launch(remember: true, done: $0) }
        _ = rig.count { first.quit(remember: true, done: $0) }
        first.cleanQuit()
        rig.jar.cookies = []
        #expect(rig.count { rig.keeper().launch(remember: true, done: $0) } == count)
        #expect(rig.jar.cookies.count == count && rig.jar.cookies.allSatisfy(\.isSessionOnly))
        #expect(rig.item == nil)
    }

    @Test func launchAfterACrashRestoresNothingAndDeletes() throws {
        let rig = try Rig()
        rig.jar.cookies = fakeCookies(session: 2, dated: 0)
        let first = rig.keeper()
        _ = rig.count { first.launch(remember: true, done: $0) }
        _ = rig.count { first.quit(remember: true, done: $0) }  // kept, but no clean quit: a crash
        rig.jar.cookies = []
        #expect(rig.item != nil)
        #expect(rig.count { rig.keeper().launch(remember: true, done: $0) } == 0)
        #expect(rig.jar.cookies.isEmpty && rig.item == nil)
    }

    @Test func launchWithTheSwitchOffRestoresNothingAndDeletes() throws {
        let rig = try Rig()
        rig.secrets.items[rig.service] = try SignIns.encode(fakeCookies(session: 2, dated: 0))
        #expect(rig.count { rig.keeper().launch(remember: false, done: $0) } == 0)
        #expect(rig.jar.cookies.isEmpty && rig.item == nil)
    }

    /// A missing, corrupt or unreadable item: nothing comes back, `done` is still heard (every tab opens).
    @Test(arguments: ["missing", "corrupt", "error"])
    func aBadItemSkipsAndTheLaunchGoesOn(problem: String) throws {
        let rig = try Rig()
        if problem == "corrupt" { rig.secrets.items[rig.service] = Data("not an item".utf8) }
        if problem == "error" { rig.secrets.failure = .status(-25308) }
        #expect(rig.count { rig.keeper().launch(remember: true, done: $0) } == 0)
        #expect(rig.jar.cookies.isEmpty)
        if problem == "corrupt" { #expect(rig.item == nil) }
        if problem == "error" { #expect(rig.lines.contains { $0.contains("keychain status -25308") }) }
    }

    @Test func logsHoldCountsNeverACookie() throws {
        let rig = try Rig()
        rig.jar.cookies = (0..<2).compactMap { fakeCookie("name-\($0)", session: true) }
        let first = rig.keeper()
        _ = rig.count { first.launch(remember: true, done: $0) }
        _ = rig.count { first.quit(remember: true, done: $0) }
        first.cleanQuit()
        _ = rig.count { rig.keeper().launch(remember: true, done: $0) }
        let text = rig.lines.joined(separator: "\n")
        #expect(text.contains("kept 2") && text.contains("restored 2"))
        for secret in ["name-", "fake-1", "example.test"] { #expect(!text.contains(secret)) }
    }

    @Test func forgetDeletesTheItem() throws {
        let rig = try Rig()
        rig.secrets.items[rig.service] = Data("x".utf8)
        rig.keeper().forget()
        #expect(rig.item == nil)
    }

    @Test(arguments: [
        (profile: String?.none, service: "io.github.jankylewis.nhetrinh.signins.default"),
        (profile: "", service: "io.github.jankylewis.nhetrinh.signins.default"),
        (profile: "readback", service: "io.github.jankylewis.nhetrinh.signins.readback"),
    ])
    func oneServicePerProfile(profile: String?, service: String) {
        #expect(SignIns.service(profile: profile) == service)
    }
}
