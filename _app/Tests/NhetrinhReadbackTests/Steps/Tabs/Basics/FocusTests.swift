import Foundation
import Testing
@testable import NhetrinhReadback

// D25 (amends D18): only the steps WebKit refuses in a hidden page (R26a, R26b) may bring nhetrinh to
// the front, and only with `--allow-focus`; the report says which step took the focus.

@Test(arguments: [
    (["readback"], false), (["readback", "--allow-focus"], true),
    (["readback", "--steps", "R1", "--allow-focus"], true), (["readback", "--allow-focus", "--steps", "R1"], true),
])
func allowFocusIsAFlagWithNoValue(arguments: [String], allowed: Bool) throws {
    #expect(try Options(arguments, known: known).allowFocus == allowed)
}

@Test(arguments: [["readback", "--allow-focus", "--allow-focus"], ["readback", "--allow-focus", "R1"],
                  ["readback", "--allow-focus=yes"], ["readback", "--allowfocus"]])
func allowFocusMisusedIsAUsageError(arguments: [String]) {
    #expect(throws: UsageError.self) { try Options(arguments, known: known) }
}

@Test func usageNamesTheFlag() {
    #expect(Options.usage.contains("[--allow-focus]"))
}

/// Only R26a and R26b may take the focus.
@Test func onlyTheHiddenPageStepsTakeTheFocus() {
    #expect(Focus.steps == ["R26a", "R26b"])
    #expect(BasicSteps.all.filter { Focus.steps.contains($0.id) }.count == 2)
}

/// A step that took the focus says so on its own report line.
@Test func aStepThatTookTheFocusSaysSo() {
    let line = Focus.took("the site sheet appeared")
    #expect(line.hasPrefix("took the focus (--allow-focus, D25): ") && line.hasSuffix("the site sheet appeared"))
    let result = StepResult(id: "R26a", name: "camera", verdict: .pass, detail: line)
    #expect(Report.text([result], app: URL(fileURLWithPath: "/nowhere/nhetrinh.app"))
        .contains("| R26a camera | PASS | took the focus (--allow-focus, D25): the site sheet appeared |"))
}

/// Without the flag the step stays NOT READ BACK, and the reason names the flag.
@Test func withoutTheFlagTheReasonNamesIt() {
    let why = Focus.needed("the fullscreen request was refused in a hidden page")
    #expect(why.contains("--allow-focus") && why.contains("not read back") && why.contains("hidden page"))
}

/// The header says whether the run allowed the focus.
@Test(arguments: [true, false])
func headerSaysWhetherTheFocusWasAllowed(allowed: Bool) {
    let text = Report.text([], app: URL(fileURLWithPath: "/nowhere/nhetrinh.app"), allowFocus: allowed)
    #expect(text.contains("focus: R26a, R26b may take the focus (--allow-focus, D25)") == allowed)
    #expect(text.contains("focus: never taken (D18); R26a, R26b need --allow-focus (D25)") == !allowed)
}

/// R26b leaves fullscreen through the page's own button, shown inside the fullscreen box; the page
/// never leaves by itself.
@Test func fullscreenPageHasALeaveButtonInsideTheBox() {
    let body = String(decoding: TestPageContent.reply(path: "/fullscreen").body, as: UTF8.self)
    #expect(body.contains("<div id=\"box\"") && body.contains("id=\"leave\""))
    #expect(!body.contains("setTimeout"))
}

/// A locked screen or a sleeping display hides every window: the reason says so (seen 2026-11-16).
@Test(arguments: [
    (true, true, "the screen is locked and the display is asleep: macOS hides every window"),
    (true, false, "the screen is locked: macOS hides every window"),
    (false, true, "the display is asleep: macOS hides every window"),
])
func hiddenReasonNamesTheScreen(locked: Bool, asleep: Bool, start: String) throws {
    let note = try #require(Focus.screenNote(locked: locked, asleep: asleep))
    #expect(note.hasPrefix(start))
}

@Test func anOnScreenAddsNoNote() {
    #expect(Focus.screenNote(locked: false, asleep: false) == nil)
}
