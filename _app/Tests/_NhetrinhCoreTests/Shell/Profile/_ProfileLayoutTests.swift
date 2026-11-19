import Foundation
import Testing
@testable import NhetrinhCore

/// P10-PROFILE (D29): the folders, the store and the Keychain service of each profile. HARD RULE pinned here:
/// `Default` keeps WebKit's default store and P9's service, so the headmate's sign-ins are found again.
private let support = URL(fileURLWithPath: "/Support", isDirectory: true)

@Test(arguments: [nil, ""] as [String?])
func noProfileIsDefault(profile: String?) throws {
    let layout = try #require(ProfileLayout(applicationSupport: support, profile: profile))
    #expect(layout.isDefault && layout.name == "Default")
    #expect(layout.folder.path == "/Support/nhetrinh/Default")
    #expect(layout.legacyFolder.path == "/Support/nhetrinh", "P9 kept Default's files at the root")
}

/// The hard rule: a store of its own for Default would lose every cookie; another service, every kept sign-in.
@Test func defaultKeepsTheDefaultStoreAndP9sService() throws {
    let layout = try #require(ProfileLayout(applicationSupport: support, profile: nil))
    #expect(layout.webStore == .standard)
    #expect(layout.keychainService == "io.github.jankylewis.nhetrinh.signins.default")
    #expect(layout.info == ProfileInfo(version: 1, name: "Default", webStore: "default",
                                       keychainService: "io.github.jankylewis.nhetrinh.signins.default"))
}

@Test(arguments: ["readback", "work", "tên có dấu"])
func aNamedProfileHasItsOwnFolderStoreAndService(name: String) throws {
    let layout = try #require(ProfileLayout(applicationSupport: support, profile: name))
    #expect(!layout.isDefault && layout.name == name)
    #expect(layout.folder == support.appendingPathComponent("nhetrinh/\(name)", isDirectory: true))
    #expect(layout.webStore == .identifier(Profile.identifier(for: name)), "the same store as P9: its data stays")
    #expect(layout.keychainService == SignIns.service(profile: name))
    let legacy = "/Support/nhetrinh/profiles/\(Profile.identifier(for: name).uuidString)"
    #expect(layout.legacyFolder.path == legacy)
}

@Test func readbackNeverSharesDefaultsFolderStoreOrService() throws {
    let readback = try #require(ProfileLayout(applicationSupport: support, profile: "readback"))
    let own = try #require(ProfileLayout(applicationSupport: support, profile: nil))
    #expect(readback.folder != own.folder && readback.webStore != own.webStore)
    #expect(readback.keychainService != own.keychainService)
}

/// `default` in any case would be Default's folder on a disk that ignores case, and its Keychain item.
@Test(arguments: ["Default", "default", "DEFAULT", "profiles", "Profiles", "session.json", "prefs.json",
                  "running.marker", "a/b", "..", ".hidden", "x:y", "a\\b", " lead", "trail ", "line\nbreak",
                  String(repeating: "x", count: 65)])
func aNameThatCollidesOrEscapesIsRefused(name: String) {
    #expect(ProfileLayout.refusal(name) != nil)
    #expect(ProfileLayout(applicationSupport: support, profile: name) == nil)
}

@Test(arguments: ["readback", "work 2", "Đi làm", String(repeating: "x", count: 64), "defaults"])
func anOrdinaryNameIsTaken(name: String) {
    #expect(ProfileLayout.refusal(name) == nil)
}

@Test func profileJSONRoundTripsAndIsWrittenOnlyWhenItDiffers() throws {
    let folder = FileManager.default.temporaryDirectory.appendingPathComponent("nhetrinh-info-\(UUID())")
    defer { try? FileManager.default.removeItem(at: folder) }
    let info = try #require(ProfileLayout(applicationSupport: support, profile: "readback")).info
    #expect(try info.write(in: folder))
    #expect(ProfileInfo.read(from: folder) == info)
    #expect(try !info.write(in: folder), "the same record: no write")
    let text = try String(contentsOf: folder.appendingPathComponent("profile.json"), encoding: .utf8)
    #expect(text.contains("\"webStore\" : \"\(Profile.identifier(for: "readback").uuidString)\""))
    #expect(text.contains("\"version\" : 1"))
    try Data("not json".utf8).write(to: folder.appendingPathComponent("profile.json"))
    #expect(ProfileInfo.read(from: folder) == nil)
    #expect(try info.write(in: folder), "a damaged record is written again")
}
