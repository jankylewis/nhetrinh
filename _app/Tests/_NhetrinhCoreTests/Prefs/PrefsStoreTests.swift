import Foundation
import Testing
@testable import NhetrinhCore

// P4: `prefs.json`. A corrupt file gives the defaults and the bad file is kept as `prefs.bad.json`.

private func folder() throws -> URL {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("prefs-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
}

private func custom(_ appearance: Appearance) -> Prefs {
    var prefs = Prefs()
    prefs.zoom = ["example.com": 1.25, "127.0.0.1": 0.75]
    prefs.searchEngine = .duckDuckGo
    prefs.idleUnloadMinutes = 30
    prefs.appearance = appearance
    return prefs
}

@Test(arguments: Appearance.allCases)
func prefsRoundTrip(appearance: Appearance) throws {
    let dir = try folder()
    try PrefsStore.save(custom(appearance), in: dir)
    #expect(PrefsStore.load(from: dir) == custom(appearance))
}

@Test func noFileGivesTheDefaults() throws {
    let prefs = PrefsStore.load(from: try folder())
    #expect(prefs == Prefs())
    #expect(prefs.searchEngine == .google && prefs.idleUnloadMinutes == 10 && prefs.appearance == .system)
    #expect(prefs.zoom.isEmpty)
}

@Test(arguments: ["{", "[]", "not json", "{\"zoom\": 3}"])
func corruptFileGivesDefaultsAndIsKept(text: String) throws {
    let dir = try folder()
    try Data(text.utf8).write(to: dir.appendingPathComponent(PrefsStore.fileName))
    var reasons: [String] = []
    #expect(PrefsStore.load(from: dir) { reasons.append($0) } == Prefs())
    let bad = dir.appendingPathComponent(PrefsStore.badFileName)
    #expect(try String(contentsOf: bad, encoding: .utf8) == text)
    #expect(!FileManager.default.fileExists(atPath: dir.appendingPathComponent(PrefsStore.fileName).path))
    #expect(reasons.count == 1)
}

/// A missing key keeps its default; the keys that are there are read.
@Test(arguments: [
    ("{}", Prefs()),
    ("{\"searchEngine\": \"bing\"}", { var p = Prefs(); p.searchEngine = .bing; return p }()),
    ("{\"appearance\": \"dark\"}", { var p = Prefs(); p.appearance = .dark; return p }()),
    ("{\"idleUnloadMinutes\": 5}", { var p = Prefs(); p.idleUnloadMinutes = 5; return p }()),
    ("{\"zoom\": {\"a.test\": 1.5}}", { var p = Prefs(); p.zoom = ["a.test": 1.5]; return p }()),
])
func missingKeysKeepTheirDefaults(json: String, expected: Prefs) throws {
    #expect(Prefs.decode(Data(json.utf8)) == expected)
}

/// An unknown value falls back: appearance to System, engine to Google, minutes and zoom to range.
@Test(arguments: [
    "{\"appearance\": \"sepia\"}", "{\"appearance\": 3}", "{\"searchEngine\": \"altavista\"}",
    "{\"idleUnloadMinutes\": 0}", "{\"idleUnloadMinutes\": -4}", "{\"zoom\": {\"a.test\": \"big\"}}",
])
func unknownValuesFallBack(json: String) throws {
    let prefs = try #require(Prefs.decode(Data(json.utf8)))
    #expect(prefs.appearance == .system && prefs.searchEngine == .google && prefs.idleUnloadMinutes == 10)
    #expect(prefs.zoom.isEmpty)
}

@Test(arguments: [("{\"zoom\": {\"a.test\": 9}}", 3.0), ("{\"zoom\": {\"a.test\": 0.1}}", 0.5)])
func savedZoomIsClamped(json: String, level: Double) throws {
    #expect(Prefs.decode(Data(json.utf8))?.zoom["a.test"] == level)
}

/// System, Light, Dark, in the Settings Hub's order and words.
@Test func appearanceChoices() {
    #expect(Appearance.allCases.map(\.title) == ["System", "Light", "Dark"])
    #expect(Appearance.allCases.map(\.rawValue) == ["system", "light", "dark"])
}
