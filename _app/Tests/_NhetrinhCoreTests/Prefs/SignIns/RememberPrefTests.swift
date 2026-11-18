import Foundation
import Testing
@testable import NhetrinhCore

/// P9-REMEMBER (D28): the switch is on by default; a prefs file from before P9 (no key) reads as on; only a
/// JSON boolean sets it (F4: a number is not a boolean).
struct RememberPrefTests {
    @Test(arguments: [
        (json: "{}", on: true), (json: "{\"rememberSignIns\": false}", on: false),
        (json: "{\"rememberSignIns\": true}", on: true), (json: "{\"rememberSignIns\": 0}", on: true),
        (json: "{\"rememberSignIns\": \"no\"}", on: true),
        (json: "{\"searchEngine\": \"bing\", \"appearance\": \"dark\", \"idleUnloadMinutes\": 5}", on: true),
    ])
    func theSwitchReads(json: String, on: Bool) {
        #expect(Prefs.decode(Data(json.utf8))?.rememberSignIns == on)
    }

    @Test(arguments: [true, false])
    func theSwitchIsSaved(on: Bool) throws {
        var prefs = Prefs()
        prefs.rememberSignIns = on
        #expect(Prefs.decode(try prefs.encoded()) == prefs)
    }

    @Test func clearAllKeepsTheSwitch() {
        var prefs = Prefs()
        prefs.rememberSignIns = false
        prefs.forgetSites()
        #expect(prefs.rememberSignIns == false)
    }
}
