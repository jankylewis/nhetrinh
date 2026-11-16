---
name: nhetrinh-develop
description: "Build one nhetrinh phase through its gate: risks, failing tests, build, conventions, tests, install, readback, budget, hubs, one PR."
---

# nhetrinh-develop

Use for any change to nhetrinh. The gate is in `hubs/product/plan/_PLAN.md` ("The gate").
Run every command from the repository root. Read `CLAUDE.md` first: it holds the laws.

## Before you start

- P0 (the harness) passes its gate before any feature work (`DECISIONS.md` D14).
- A mate works only in its worktree, on the paths its brief names. It commits only with a grant.
- The machine is shared: one heavy command at a time, always `nice -n 10`. Never run the
  benchmark. Never start the app unless the brief says so. Never capture the screen.

## The gate (every phase, in this order)

1. Read `hubs/bugs/TRIAGE.md` and `hubs/failures/TRIAGE.md`. Write the phase's foreseen risks.
   Grep the signatures there that touch your change.
2. Write the failing tests first, in `_app/Tests/_NhetrinhCoreTests/`, parameterized
   (Swift Testing `@Test(arguments:)`). Logic that needs no AppKit goes in `NhetrinhCore`.
   A bug fix starts with a test that fails. A test that cannot fail is a defect.
3. Build the phase. AppKit and WebKit only: no SwiftUI, no package dependency.
4. Conventions, 0 violations:
   `python3 _app/scripts/conventions/_check.py`
   If you changed the checker: `python3 -m unittest discover -s _app/scripts/conventions -p 'test_*.py'`
5. Unit tests, all green; the report quotes the count:
   `nice -n 10 _app/scripts/test.sh`
   Never plain `swift test`: it sometimes loses the Swift Testing plugin (NT-GAT-001).
6. Build, then install (the readback runs on the installed app, never on the build folder):
   `nice -n 10 _app/scripts/_build.sh` (output `_app/build/nhetrinh.app`), then
   `_app/scripts/install.sh` (only on the seat the brief names; it quits a running copy).
7. Readback: every step of this phase and of all earlier phases is PASS. See `nhetrinh-readback`.
8. Lightness budget, measured inside the readback (step R8):

   | Measure | Budget |
   |---|---|
   | App process, one simple tab | 40 MB |
   | App + all helper processes, one simple tab | 110 MB |
   | `nhetrinh.app` on disk | 1 MB |
   | Idle CPU, tabs open, nothing playing | 2 % |

   A phase that breaks a budget stops until the cost is removed or the headmate accepts a new
   number (a row in `DECISIONS.md`).
9. Hubs in the same PR: feature rows, bug / failure / lesson / tool-gap entries, evidence paths.
   See `nhetrinh-hubs`.
10. One PR per phase. CI green, then self-merge, version tag, report. See `nhetrinh-ship`.

A step the readback cannot drive is "not read back". It is never counted as passed.

## Conventions the checker enforces (`_app/scripts/conventions/`)

| Rule | Limit |
|---|---|
| Entries per folder (dot folders exempt) | at most 5, exactly one starts with `_` |
| `.md` file | 100 lines |
| Code (`.swift .py .c .sh .yml`) | 150 lines, 120 characters a line |
| Function (Swift, Python) | 30 lines, 5 parameters |
| Swift | no force unwrap, no `try!`, no `as!` |
| `Package.swift` | no dependency |

Past 5 entries, group by meaning; never widen a folder.

## Where code goes

| Path | Holds |
|---|---|
| `_app/_Sources/_Nhetrinh/` | the app: `_Browser/`, `UI/`, `Support/` |
| `_app/_Sources/NhetrinhCore/` | pure logic, unit tested |
| `_app/_Sources/NhetrinhReadback/` | the readback tool |
| `_app/Tests/_NhetrinhCoreTests/` | tests of `NhetrinhCore` |
| `_app/Tests/NhetrinhReadbackTests/` | tests of the readback tool's pure parts (icon match, report, options) |

## Report

A mate ends with `READY <task>` (the files changed, the real last lines of the checker and of
`test.sh`) or `BLOCKED <task>` (the exact command and error, after two own attempts).
Say what you ran and what you saw. Never report "works" for something you did not run.
