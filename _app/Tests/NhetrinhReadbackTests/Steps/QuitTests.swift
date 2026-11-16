import Foundation
import Testing
@testable import NhetrinhReadback

// NT-TG-004: the readback's own instance outlived its run (22:13). The final quit now waits for
// the app to exit and, past the wait, ends only the instance it launched, by that pid.

/// A pretend app: whether it obeys a quit request, whether a signal 9 ends it.
private final class FakeApp {
    var running: Bool
    let obeysQuit: Bool
    let diesOnKill: Bool
    var asked = 0
    var killed: [pid_t] = []

    init(running: Bool = true, obeysQuit: Bool, diesOnKill: Bool = true) {
        self.running = running
        self.obeysQuit = obeysQuit
        self.diesOnKill = diesOnKill
    }

    func end(_ pid: pid_t) -> QuitOutcome {
        Ending.end(pid, isRunning: { self.running }, askToQuit: {
            self.asked += 1
            if self.obeysQuit { self.running = false }
        }, kill: { target in
            self.killed.append(target)
            if self.diesOnKill { self.running = false }
        }, wait: { _, condition in condition() })
    }
}

@Test(arguments: [
    (obeys: true, dies: true, outcome: QuitOutcome.quit, killed: [] as [pid_t]),
    (false, true, .killed(4242), [4242]),
    (false, false, .survived(4242), [4242]),
])
func finalQuitEndsOnlyItsOwnInstance(obeys: Bool, dies: Bool, outcome: QuitOutcome, killed: [pid_t]) {
    let app = FakeApp(obeysQuit: obeys, diesOnKill: dies)
    #expect(app.end(4242) == outcome)
    #expect(app.asked == 1, "the app is asked to quit first, as the user quits it")
    #expect(app.killed == killed, "signal 9 only past the wait, and only to the launched pid")
}

@Test func nothingRunningIsNotTouched() {
    let app = FakeApp(running: false, obeysQuit: true)
    #expect(app.end(4242) == .notRunning && app.asked == 0 && app.killed.isEmpty)
}

@Test(arguments: [QuitOutcome.notRunning, .quit, .killed(77), .survived(77)])
func everyEndingIsSaid(outcome: QuitOutcome) {
    #expect(outcome.line.hasPrefix("end: "))
    if case .killed = outcome { #expect(outcome.line.contains("pid 77") && outcome.line.contains("signal 9")) }
    if case .survived = outcome { #expect(outcome.line.contains("still runs")) }
}

@Test func reportSaysHowTheRunEnded() {
    let app = URL(fileURLWithPath: "/nowhere/nhetrinh.app")
    #expect(Report.text([], app: app, ending: .killed(77)).contains(QuitOutcome.killed(77).line))
    #expect(!Report.text([], app: app).contains("end: "))
}
