import Foundation
import Testing
@testable import NhetrinhCore

// P4P6-REVIEW (REVIEW_P4_P6.md, F4), red on p6/memory 96130c6: `Prefs.decode` says "a key of the wrong
// kind keeps its default", but JSONSerialization gives a JSON boolean as an NSNumber, and `as? Int` /
// `as? Double` take it: `true` is 1 minute (a tab unloaded after 1 min idle), `false` a zoom of 0 (50 %).

/// A boolean is not minutes; a real number of the same value is (the control).
@Test(arguments: [(#"{"idleUnloadMinutes": true}"#, Prefs.defaultIdleMinutes), (#"{"idleUnloadMinutes": 1}"#, 1)])
func aBooleanIsNotMinutes(json: String, minutes: Int) {
    #expect(Prefs.decode(Data(json.utf8))?.idleUnloadMinutes == minutes)
}

/// A boolean is not a zoom level; a real number is (the control).
@Test(arguments: [(#"{"zoom": {"a.test": true}}"#, nil), (#"{"zoom": {"a.test": false}}"#, nil),
                  (#"{"zoom": {"a.test": 1.5}}"#, 1.5)] as [(String, Double?)])
func aBooleanIsNotAZoomLevel(json: String, level: Double?) {
    #expect(Prefs.decode(Data(json.utf8))?.zoom["a.test"] == level)
}

// P4P6-FIX-1, red first: F7 (a bad value is ignored alone, never the whole file), F10 (hosts read lower
// case, as `Zoom.hostKey` gives them), F6 (Clear All forgets the per-site settings).

/// A `zoom` of the wrong kind is ignored alone: the other keys are read.
@Test(arguments: [#"{"zoom": 3, "searchEngine": "bing"}"#, #"{"zoom": [], "searchEngine": "bing"}"#,
                  #"{"zoom": "x", "searchEngine": "bing"}"#])
func aBadZoomCostsNothingElse(json: String) throws {
    let prefs = try #require(Prefs.decode(Data(json.utf8)))
    #expect(prefs.searchEngine == .bing && prefs.zoom.isEmpty)
}

@Test(arguments: [("Example.COM", "example.com"), ("a.test", "a.test")])
func hostsAreReadLowerCase(saved: String, key: String) {
    let prefs = Prefs.decode(Data(#"{"zoom": {"\#(saved)": 1.5}}"#.utf8))
    #expect(prefs?.zoom == [key: 1.5])
}

@Test func forgetSitesKeepsTheAppSettings() {
    var prefs = Prefs()
    prefs.zoom = ["a.test": 1.5]
    prefs.searchEngine = .bing
    prefs.appearance = .dark
    prefs.idleUnloadMinutes = 3
    prefs.forgetSites()
    #expect(prefs.zoom.isEmpty)
    #expect(prefs.searchEngine == .bing && prefs.appearance == .dark && prefs.idleUnloadMinutes == 3)
}
