# nhetrinh — briefing for every agent

nhetrinh is a very small macOS browser: WebKit (`WKWebView`) in a Swift + AppKit shell, with a
vertical tab sidebar. Lightness first, speed second, the basics only. The repository is public.

Read first, in this order:
1. `hubs/product/plan/_PLAN.md`: the phases, the gate every phase passes, the lightness budget.
2. `hubs/_SCHEMA.md`, then `hubs/bugs/TRIAGE.md` and `hubs/failures/TRIAGE.md`: what went wrong before.
3. `hubs/product/plan/DECISIONS.md`: what is decided, and by whom.

## Laws

1. **Harness first.** No feature work until phase P0 has passed its gate (headmate, D14).
2. **Conventions are checked by tool, never by eye.** `python3 _app/scripts/conventions/_check.py`
   prints 0 violations before every commit. It checks: exactly one `_` entry per folder (the most
   critical one) and at most 5 entries; `.md` 100 lines; code 150 lines and 120 characters a line;
   function 30 lines and 5 parameters; no force unwrap, `try!`, `as!`; no package dependency.
   Past 5 entries, group by meaning; never widen a folder.
3. **Tests first.** Logic that needs no AppKit lives in `NhetrinhCore`, with parameterized Swift
   Testing tests. A bug fix starts with a test that fails. A test that cannot fail is a defect.
   Run tests only with `_app/scripts/test.sh` (plain `swift test` is flaky here: NT-GAT-001).
4. **Readback is part of done.** `nhetrinh-readback` uses the installed app as its end user and
   gives a verdict per step. NOT READ BACK is never a pass. "Merged" and "tests green" are not a
   readback. It runs on one seat at a time, the seat a brief names: there is only one app instance.
5. **Lightness budget:** app process 40 MB, app + helpers 110 MB, bundle 1 MB, idle CPU 2 %.
   A change that breaks it stops until the cost is removed or the headmate accepts a new number.
6. **Hubs in the same change.** Every bug, failure, lesson, tool gap and feature gets its entry
   (`hubs/_SCHEMA.md`). Every claim cites a source. Write "not proven" for what is not proven.
7. **The machine is shared with the headmate.** One heavy command at a time, always with
   `nice -n 10`. Never run the benchmark (`hubs/product/rnd`). Never start the app yourself unless
   your brief says so. Never capture the screen.
8. **Public repository.** No secrets, e-mails, person names, work names or absolute personal
   paths in any file or commit. Name people by role (`headmate`).
9. **Apple frameworks only.** AppKit and WebKit; no SwiftUI; no third-party package.

## Commands (from the repository root)

| What | Command |
|---|---|
| Conventions | `python3 _app/scripts/conventions/_check.py` |
| The checker's own tests | `python3 -m unittest discover -s _app/scripts/conventions -p 'test_*.py'` |
| Unit tests | `nice -n 10 _app/scripts/test.sh` |
| Build the app | `nice -n 10 _app/scripts/_build.sh` (output: `_app/build/nhetrinh.app`) |
| Install (only when the brief says so) | `_app/scripts/install/_install.sh` |
| Readback as a granted app (only when the brief says so) | `_app/scripts/install/readback_app.sh run` (NT-TG-003) |
| Readback (only when the brief says so) | `cd _app && swift run nhetrinh-readback` |

## Map

| Path | Holds |
|---|---|
| `_app/_Sources/_Nhetrinh/` | the app: `_Browser/` (window, tabs, WebKit), `UI/`, `Support/` (log, bench hooks) |
| `_app/_Sources/NhetrinhCore/` | pure logic, no AppKit: address parsing, profiles; unit tested |
| `_app/_Sources/NhetrinhReadback/` | the readback tool: `_Steps/` (R1-R8; `Probe.swift`: the app probe, D23), `Driver/` (Dock via Accessibility, processes) |
| `_app/Tests/` | Swift Testing: `_NhetrinhCoreTests/` (`NhetrinhCore`), `NhetrinhReadbackTests/` (readback tool), `NhetrinhTests/` (app menu wiring) |
| `_app/scripts/` | `_build.sh`, `install/` (app, readback app), `test.sh`, `conventions/` (the checker), `VERSION` |
| `_app/assets/_icon/` | the app icon and the tools that made it |
| `hubs/` | learnings (bugs, failures, lessons, tool gaps) and product (features, plan, rnd) |

## Fleet rules

The fleet is `nhetrinh`: matemaster `nhetrinh_mm`, mates `nhetrinh_1` and `nhetrinh_2`.

- A mate works only in the worktree and on the paths its brief names. It never edits another
  mate's paths, never touches `master`, never pushes and never merges.
- A mate does not commit unless its brief says the headmate granted it. Without the grant it
  leaves the change in its worktree; the matemaster reviews the diff and commits.
- A mate ends a task with one of two reports:
  `READY <task>`: the files changed, and the real last lines of the checker and of `test.sh`.
  `BLOCKED <task>`: the exact command and error. Two own attempts first, then report.
- A mate never reports "works" for something it did not run. It says what it ran and what it saw.
- The matemaster steers: it dispatches, reviews the evidence, merges and ships. It does not do a
  mate's work. A mate never reviews its own work as final: another seat reads it.
- Other fleets, their seats and their folders are off limits. So is everything outside this
  repository.
