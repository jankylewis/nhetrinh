import Foundation
import Testing
@testable import NhetrinhCore

// P1 tests (hubs/product/plan/M1_DAILY_DRIVER.md), written red first on a stub (P1-PREP-1, DECISIONS.md D22);
// green since P1-BUILD-1 built `UnloadPolicy.tabsToUnload`.

private let now = Date(timeIntervalSinceReferenceDate: 1_000_000)
private let limit: TimeInterval = 600

/// How long the tab under test has been idle. Today's code unloads a tab strictly older than the
/// limit (P0's `unloadIdleTabs`, _app/_Sources/_Nhetrinh/_Browser/_Window/BrowserWindowController+Tabs.swift:87).
enum Idle: TimeInterval, CustomStringConvertible {
    case underTheLimit = 599
    case atTheLimit = 600
    case overTheLimit = 601

    var description: String { "idle \(Int(rawValue)) s of \(Int(limit))" }
}

struct UnloadCase: CustomTestStringConvertible {
    let idle: Idle
    let selected: Bool
    let playing: Bool
    let unloads: Bool

    var testDescription: String {
        "\(idle), \(selected ? "selected" : "background"), \(playing ? "playing" : "silent")"
    }
}

/// The table: idle time x selected x playing. Only an idle, background, silent tab is unloaded;
/// a playing tab never is (NT-TAB-001), a selected tab never is.
let unloadTable = [
    UnloadCase(idle: .underTheLimit, selected: false, playing: false, unloads: false),
    UnloadCase(idle: .underTheLimit, selected: false, playing: true, unloads: false),
    UnloadCase(idle: .underTheLimit, selected: true, playing: false, unloads: false),
    UnloadCase(idle: .underTheLimit, selected: true, playing: true, unloads: false),
    UnloadCase(idle: .atTheLimit, selected: false, playing: false, unloads: false),
    UnloadCase(idle: .atTheLimit, selected: false, playing: true, unloads: false),
    UnloadCase(idle: .atTheLimit, selected: true, playing: false, unloads: false),
    UnloadCase(idle: .atTheLimit, selected: true, playing: true, unloads: false),
    UnloadCase(idle: .overTheLimit, selected: false, playing: false, unloads: true),
    UnloadCase(idle: .overTheLimit, selected: false, playing: true, unloads: false),
    UnloadCase(idle: .overTheLimit, selected: true, playing: false, unloads: false),
    UnloadCase(idle: .overTheLimit, selected: true, playing: true, unloads: false),
]

/// Three tabs: 0 a control that must always be unloaded (idle 1 h, silent, background), 1 the tab
/// under test, 2 a fresh tab that is selected when the tab under test is not. The control makes
/// every case fail on a policy that unloads nothing.
@Test(arguments: unloadTable)
func unloadPolicyTable(run: UnloadCase) {
    let control = UnloadPolicy.TabState(lastActive: now - 3600, isLoaded: true, isPlaying: false)
    let tested = UnloadPolicy.TabState(lastActive: now - run.idle.rawValue, isLoaded: true, isPlaying: run.playing)
    let fresh = UnloadPolicy.TabState(lastActive: now, isLoaded: true, isPlaying: false)
    let unloaded = UnloadPolicy.tabsToUnload([control, tested, fresh], selected: run.selected ? 1 : 2,
                                             now: now, idleLimit: limit)
    #expect(unloaded == (run.unloads ? [0, 1] : [0]))
}

/// A tab that is already unloaded is not unloaded again; a playing tab is kept even after a day.
@Test(arguments: [(loaded: false, playing: false, expected: [0]), (loaded: true, playing: true, expected: [0])])
func unloadPolicyEdges(loaded: Bool, playing: Bool, expected: [Int]) {
    let control = UnloadPolicy.TabState(lastActive: now - 3600, isLoaded: true, isPlaying: false)
    let tested = UnloadPolicy.TabState(lastActive: now - 86_400, isLoaded: loaded, isPlaying: playing)
    #expect(UnloadPolicy.tabsToUnload([control, tested], selected: nil, now: now, idleLimit: limit) == expected)
}

/// Put Tab to Idle / Put Other Tabs to Idle (headmate, 2026-11-19): idle time does not count, the user asks now.
/// Tabs: 0 and 5 loaded and silent, 1 loaded, 2 playing, 3 already idle, 4 holding the microphone.
@Test(arguments: [(chosen: 0, others: false, expected: [0]), (chosen: 2, others: false, expected: []),
                  (chosen: 3, others: false, expected: []), (chosen: 4, others: false, expected: []),
                  (chosen: 1, others: true, expected: [0, 5]), (chosen: 0, others: true, expected: [1, 5])])
func tabsToIdleTakesOnlyLoadedSilentTabs(chosen: Int, others: Bool, expected: [Int]) {
    func tab(loaded: Bool = true, playing: Bool = false, capturing: Bool = false) -> UnloadPolicy.TabState {
        UnloadPolicy.TabState(lastActive: now, isLoaded: loaded, isPlaying: playing, isCapturing: capturing)
    }
    let tabs = [tab(), tab(), tab(playing: true), tab(loaded: false), tab(capturing: true), tab()]
    #expect(UnloadPolicy.tabsToIdle(tabs, chosen: chosen, others: others) == expected)
}
