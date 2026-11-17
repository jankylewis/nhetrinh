import Foundation
import NhetrinhCore
import Testing
@testable import NhetrinhReadback

// P8-R43-FIX, R43: the save at quit must be the version the app writes (`TreeSession.version`), never a
// number pinned in the step (NT-GAT-014). Red first: the step pinned version 2 after P8-GROUPS-1 wrote 3.

private let tabs = (1...3).compactMap { page in
    URL(string: "http://127.0.0.1:1/page/\(page)").map { SessionTab(url: $0, title: "nhetrinh test \(page)") }
}
private let old = Session(tabs: tabs, selectedIndex: 1, sidebarWidth: 220, collapsed: false, version: 1)

/// The file the app writes at quit: `TreeSessionStore.encode`, as `TreeSessionStore.save` does.
private func appSave(_ tabs: [SessionTab]) -> Data {
    let session = TreeSession(migrating: Session(tabs: tabs, selectedIndex: 1, sidebarWidth: 220, collapsed: false))
    return (try? TreeSessionStore.encode(session)) ?? Data()
}

/// The same save with its version changed: what an older or a newer build would have written.
private func appSave(version: Int) -> Data {
    let text = String(decoding: appSave(tabs), as: UTF8.self)
    let current = "\"version\":\(TreeSession.version)"
    return Data(text.replacingOccurrences(of: current, with: "\"version\":\(version)").utf8)
}

@Test(arguments: [
    ("the app's save", appSave(tabs), true),
    ("the app's save with other tabs", appSave(Array(tabs.prefix(2))), false),
    ("a version 2 save", appSave(version: 2), false),
    ("a version 1 file (the one the step wrote)", (try? JSONEncoder().encode(old)) ?? Data(), false),
    ("a newer version", appSave(version: TreeSession.version + 1), false),
    ("no file", Data(), false),
] as [(String, Data, Bool)])
func r43AcceptsOnlyTheVersionTheAppWrites(_ name: String, bytes: Data, accepted: Bool) {
    #expect(VersionOneStep.isCurrentSave(bytes, tabs: tabs) == accepted, "\(name)")
}

@Test func r43ReadsTheAppsVersionFromTheSaveItself() {
    #expect(TreeSessionStore.version(of: appSave(tabs)) == TreeSession.version)
}
