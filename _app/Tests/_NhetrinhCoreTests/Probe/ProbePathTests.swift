import Foundation
import Testing
@testable import NhetrinhCore

@Test(arguments: [
    (["NHT_READBACK": "1"], true),
    (["NHT_READBACK": "0"], false),
    (["NHT_READBACK": "true"], false),
    (["NHT_READBACK": ""], false),
    ([String: String](), false),
    (["NHT_PROFILE": "readback"], false),
])
func probeIsOnOnlyForOne(env: [String: String], on: Bool) {
    #expect(ProbePath.isOn(env) == on)
}

@Test(arguments: [Int32(1), 4242, 99999, Int32.max])
func socketIsInAFolderOfItsOwnPerProcess(pid: Int32) throws {
    let temp = "/var/folders/ab/cdefghijklmnopqrstuvwxyz0000gn/T/"
    let path = ProbePath.socket(pid: pid, temp: temp)
    #expect(path == temp + "nhetrinh-probe-\(pid)/probe.sock")
    #expect(ProbePath.folder(pid: pid, temp: temp) + "/probe.sock" == path)
    #expect(path.utf8.count <= ProbePath.maxLength)
}

@Test(arguments: ["/var/folders/x/T", "/var/folders/x/T/"])
func folderJoinsWithOrWithoutSlash(temp: String) {
    #expect(ProbePath.folder(pid: 7, temp: temp) == "/var/folders/x/T/nhetrinh-probe-7")
}

@Test func userTempIsAnAbsoluteFolder() {
    let temp = ProbePath.userTemp()
    #expect(temp.hasPrefix("/") && temp.hasSuffix("/"))
}

@Test(arguments: [
    ("t", ShortcutKeys.command, "⌘T"),
    ("w", ShortcutKeys.command, "⌘W"),
    ("z", ShortcutKeys([.command, .shift]), "⇧⌘Z"),
    ("[", ShortcutKeys.command, "⌘["),
    ("a", ShortcutKeys([.control, .option, .shift, .command]), "⌃⌥⇧⌘A"),
    ("", ShortcutKeys.command, ""),
])
func shortcutReadsLikeTheMenu(key: String, keys: ShortcutKeys, text: String) {
    #expect(Shortcut.text(key: key, keys: keys) == text)
}
