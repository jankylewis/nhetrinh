import Foundation
import Testing
@testable import NhetrinhReadback

// P4 (hubs/product/plan/M2_REAL_SITES_WORK.md): the steps R27-R30a and their local pages.

@Test func toolStepsAreR27ToR30a() {
    #expect(ToolSteps.all.map(\.id) == ["R27", "R28", "R29", "R30", "R30a"])
}

/// Each page carries what its step reads.
@Test(arguments: [
    ("/find", "<title>\(ToolPages.findTitle)</title>"), ("/find", "Example"),
    ("/cookie/set", "document.cookie = 'nhetrinh=readback; max-age=3600; path=/'"),
    ("/cookie/set", "'\(ToolPages.cookieSetTitle)'"), ("/cookie/read", "(document.cookie || 'none')"),
    ("/scheme", "matchMedia('(prefers-color-scheme: dark)')"), ("/scheme", "addEventListener('change'"),
])
func toolPageCarriesWhatTheStepReads(path: String, part: String) {
    let reply = TestPageContent.reply(path: path)
    #expect(reply.status == "200 OK")
    #expect(String(decoding: reply.body, as: UTF8.self).contains(part))
}

/// The titles the steps wait for are the ones the pages write.
@Test func titlesMatchThePages() {
    #expect(ToolPages.cookieTitle == "cookie: " + "nhetrinh=readback")
    #expect(ToolPages.noCookieTitle == "cookie: none")
    #expect(ToolPages.schemeTitle(dark: true) == "scheme: dark")
    #expect(ToolPages.schemeTitle(dark: false) == "scheme: light")
}

/// The words R30 presses are the app's own.
@Test func clearTitleIsTheHubsButton() {
    #expect(SettingsTitles.clear == "Clear Website Data…")
}
