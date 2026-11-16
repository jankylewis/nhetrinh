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
