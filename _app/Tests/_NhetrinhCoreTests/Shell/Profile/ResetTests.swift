import Foundation
import Testing
@testable import NhetrinhCore

/// P10-PROFILE (D29): Reset profile… empties only this profile's folder, and only when it is the folder in use.
@Test(arguments: [nil, "readback"] as [String?])
func resetEmptiesOnlyThisProfilesFolder(profile: String?) throws {
    let rig = MigrationRig()
    let layout = rig.layout(profile)
    let own = layout.name
    for name in ["session.json", "prefs.json", "session.bad.json", "profile.json", "running.marker"] {
        try rig.put("\(own)/\(name)")
    }
    try rig.put("\(own)/sub/file")
    let other = profile == nil ? "readback" : "Default"
    try rig.put("\(other)/session.json", "other")
    try rig.put("session.json", "a root file")
    let gone = try ProfileReset.empty(layout, inUse: layout.folder)
    #expect(gone == ["prefs.json", "session.bad.json", "session.json", "sub"])
    #expect(rig.exists("\(own)/profile.json") && rig.exists("\(own)/running.marker"))
    #expect(rig.read("\(other)/session.json") == "other" && rig.read("session.json") == "a root file")
}

/// After a failed migration the root is in use and holds every profile: a reset there is refused.
@Test func resetIsRefusedWhenTheFolderInUseIsNotTheProfiles() throws {
    let rig = MigrationRig()
    try rig.put("session.json", "P9's")
    let layout = rig.layout()
    #expect(throws: ProfileReset.Refusal.notInUse) { try ProfileReset.empty(layout, inUse: layout.legacyFolder) }
    #expect(throws: ProfileReset.Refusal.notInUse) { try ProfileReset.empty(layout, inUse: rig.layout("x").folder) }
    #expect(rig.read("session.json") == "P9's")
}
