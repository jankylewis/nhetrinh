import Foundation
import Testing
@testable import NhetrinhCore

// P6 (hubs/product/plan/M3_V1_RELEASE.md): the UnloadPolicy table grows by the pressure level.
// Written red first on a stub that ignored the level (P6-BUILD-1).

private let now = Date(timeIntervalSinceReferenceDate: 1_000_000)
/// The normal limit, as the Settings Hub's 10 minutes give it.
private let normal: TimeInterval = 600

struct PressureCase: CustomTestStringConvertible {
    let pressure: UnloadPolicy.Pressure
    let idle: TimeInterval
    var selected = false
    var playing = false
    let unloads: Bool

    var testDescription: String {
        "\(pressure), idle \(Int(idle)) s, \(selected ? "selected" : "background"), \(playing ? "playing" : "silent")"
    }
}

/// Normal: idle past the limit. Warning: idle past 1 minute. Critical: every background tab.
/// At every level a playing tab and the selected tab are kept.
let pressureTable = [
    PressureCase(pressure: .normal, idle: 0, unloads: false),
    PressureCase(pressure: .normal, idle: 61, unloads: false),
    PressureCase(pressure: .normal, idle: 601, unloads: true),
    PressureCase(pressure: .warning, idle: 0, unloads: false),
    PressureCase(pressure: .warning, idle: 60, unloads: false),
    PressureCase(pressure: .warning, idle: 61, unloads: true),
    PressureCase(pressure: .warning, idle: 601, unloads: true),
    PressureCase(pressure: .critical, idle: 0, unloads: true),
    PressureCase(pressure: .critical, idle: 61, unloads: true),
    PressureCase(pressure: .critical, idle: 601, unloads: true),
    PressureCase(pressure: .normal, idle: 86_400, playing: true, unloads: false),
    PressureCase(pressure: .warning, idle: 86_400, playing: true, unloads: false),
    PressureCase(pressure: .critical, idle: 86_400, playing: true, unloads: false),
    PressureCase(pressure: .warning, idle: 86_400, selected: true, unloads: false),
    PressureCase(pressure: .critical, idle: 86_400, selected: true, unloads: false),
]

/// Three tabs: 0 a control idle 1 day (always unloaded), 1 the tab under test, 2 a fresh tab,
/// selected when the tab under test is not. The control makes a policy that unloads nothing fail.
/// Row 2 is judged by its own rows (idle 0); at critical it goes too when it is in the background.
@Test(arguments: pressureTable)
func unloadPolicyByPressure(run: PressureCase) {
    let control = UnloadPolicy.TabState(lastActive: now - 86_400, isLoaded: true, isPlaying: false)
    let tested = UnloadPolicy.TabState(lastActive: now - run.idle, isLoaded: true, isPlaying: run.playing)
    let fresh = UnloadPolicy.TabState(lastActive: now, isLoaded: true, isPlaying: false)
    let unloaded = UnloadPolicy.tabsToUnload([control, tested, fresh], selected: run.selected ? 1 : 2, now: now,
                                             idleLimit: normal, pressure: run.pressure)
    #expect(unloaded.filter { $0 < 2 } == (run.unloads ? [0, 1] : [0]))
}

/// A short normal limit (the readback's 5 s) is not made longer by a warning.
@Test(arguments: [(normal: 5.0, idle: 6.0, unloads: true), (normal: 5.0, idle: 4.0, unloads: false)])
func aWarningNeverWaitsLongerThanNormal(normal: TimeInterval, idle: TimeInterval, unloads: Bool) {
    let tested = UnloadPolicy.TabState(lastActive: now - idle, isLoaded: true, isPlaying: false)
    let unloaded = UnloadPolicy.tabsToUnload([tested], selected: nil, now: now, idleLimit: normal, pressure: .warning)
    #expect(unloaded == (unloads ? [0] : []))
}

/// The level as macOS names it and as the probe sends it.
@Test(arguments: [("normal", UnloadPolicy.Pressure.normal), ("warning", .warning), ("critical", .critical)])
func pressureLevelsByName(name: String, level: UnloadPolicy.Pressure) {
    #expect(UnloadPolicy.Pressure(rawValue: name) == level && level.rawValue == name)
}
