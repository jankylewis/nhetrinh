import Foundation
import NhetrinhCore
import Testing
@testable import NhetrinhReadback

/// R53 (P10-PROFILE): its folder is readback's, never Default's; its verdict on the folder after a clean quit.
/// R53 itself is not run here.
struct ProfileStepTests {
    @Test func theStepIsR53AndReadsOnlyReadbacksFolder() throws {
        #expect(ProfileStep.step.id == "R53")
        let support = URL(fileURLWithPath: "/Support", isDirectory: true)
        let folder = try #require(AppSession.folder(support: support))
        #expect(folder.path == "/Support/nhetrinh/readback" && ProfileStep.isReadbacks(folder))
        #expect(!ProfileStep.isReadbacks(support.appendingPathComponent("nhetrinh/Default")))
        #expect(!ProfileStep.isReadbacks(support.appendingPathComponent("nhetrinh")))
        let id = Profile.identifier(for: "readback").uuidString
        #expect(AppSession.folders(support: support).map(\.path)
                == ["/Support/nhetrinh/readback", "/Support/nhetrinh/profiles/\(id)"], "never Default's")
    }

    @Test func readbacksRecordHasItsOwnStoreAndService() throws {
        let info = try #require(ProfileStep.expectedInfo)
        #expect(info.name == "readback" && info.webStore == "75CF0542-34C3-8753-0F42-CCD2A84A40A2")
        #expect(info.keychainService == "io.github.jankylewis.nhetrinh.signins.readback")
    }

    private static let good = ProfileStep.expectedInfo
    private static let defaults = ProfileInfo(version: 1, name: "Default", webStore: "default",
                                              keychainService: SignIns.service(profile: nil))

    @Test(arguments: [
        (names: ["session.json", "profile.json"], info: good, fails: false),
        (["session.json", "profile.json", "prefs.json"], good, false),
        (["profile.json"], good, true), (["session.json"], good, true),
        (["session.json", "profile.json", "running.marker"], good, true),
        (["session.json", "profile.json"], nil, true), (["session.json", "profile.json"], defaults, true),
    ] as [(names: Set<String>, info: ProfileInfo?, fails: Bool)])
    func theVerdict(names: Set<String>, info: ProfileInfo?, fails: Bool) {
        #expect((ProfileStep.failure(names: names, info: info) != nil) == fails)
    }
}
