import Foundation
import Testing
@testable import NhetrinhCore

@Test(arguments: ["readback", "work", "a", "tên có dấu"])
func sameNameGivesSameIdentifier(name: String) {
    #expect(Profile.identifier(for: name) == Profile.identifier(for: name))
}

@Test(arguments: [("readback", "work"), ("a", "A"), ("x", "x ")])
func differentNamesGiveDifferentIdentifiers(first: String, second: String) {
    #expect(Profile.identifier(for: first) != Profile.identifier(for: second))
}

@Test func identifierIsTheFirst16BytesOfSha256() {
    // Pinned: if this value changes, every existing profile loses its data.
    // Checked outside Swift: printf 'readback' | shasum -a 256  ->  75cf0542 34c3 8753 0f42 ccd2a84a40a2 ...
    #expect(Profile.identifier(for: "readback").uuidString == "75CF0542-34C3-8753-0F42-CCD2A84A40A2")
}
