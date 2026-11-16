---
name: nhetrinh-readback
description: "Use the installed nhetrinh as its end user with nhetrinh-readback, read the verdict per step, and add a step R<n> for a new phase."
---

# nhetrinh-readback

The readback is part of done (`CLAUDE.md` law 4, `DECISIONS.md` D9). "Merged" and "tests
green" are not a readback. It runs on one seat at a time, the seat a brief names: there is
only one app instance.

## What it does

- Target `NhetrinhReadback`, product `nhetrinh-readback` (`_app/Package.swift`).
- It starts the installed app `~/Applications/nhetrinh.app` and drives it through the macOS
  Accessibility API only: press, set value, confirm. It never moves the mouse or types keys,
  starts the app without taking the focus, and uses its own browsing profile (D18).
- It needs the Accessibility permission for the terminal app (System Settings). Without it,
  the steps that drive the app are NOT READ BACK (`_PLAN.md` risk R-1).

## Run it (only on the seat the brief names)

1. `nice -n 10 _app/scripts/_build.sh`, then `_app/scripts/install.sh`.
   The readback reads the installed app, never `_app/build/`.
2. From the repository root:

   | Command | Does |
   |---|---|
   | `cd _app && swift run nhetrinh-readback` | every step; keeps the verdict file |
   | `cd _app && swift run nhetrinh-readback --steps R1,R2` | only these steps; keeps nothing |
   | `cd _app && swift run nhetrinh-readback --app <path>` | another copy of the app; keeps nothing |

3. Only a full run on the installed app writes `hubs/failures/evidence/readback/_LATEST.md`
   (`_app/_Sources/NhetrinhReadback/main.swift`, `Report.swift`). Cite that file next to a DONE phase.

## Verdicts

| Verdict | Means |
|---|---|
| `PASS` | the step ran and saw what the user should see |
| `FAIL` | the step ran and the app is wrong (`StepError.fail`) |
| `NOT READ BACK` | the step could not run (`StepError.cannotDrive`); never counted as passed |

The run verdict: `PASS (n of n)`; `FAIL (...)` when a step failed; `INCOMPLETE (...)` when no
step failed but one was not read back. Exit code: 0 all PASS, 1 a FAIL, 2 a NOT READ BACK or no step ran. A flag it does not know,
a flag without a value or an unknown step id is a usage error: exit 2, no step runs (NT-GAT-003).
A phase is DONE only when every step of it and of all earlier phases is PASS.

## The base steps (`_app/_Sources/NhetrinhReadback/_Steps/_BaseSteps.swift`, every phase)

R1 window with sidebar and address bar; R2 Dock icon has no tile; R3 an address loads its
page; R4 words become one search; R5 New Tab and Close Tab change the sidebar; R6 selecting a
row shows that tab; R7 unopened tabs cost no page process; R8 the lightness budget holds.

## Add a step R<n>

1. Take the next free id after the highest `R<n>` in `_Steps/`.
2. Write a function `(AppSession) throws -> String` that acts as the user would and returns
   what it saw, in words a reader can check.
   - `try expect(condition, "what was seen")` throws `fail` with the evidence.
   - Throw `StepError.cannotDrive("why")` when the step cannot run.
   - Use `waitUntil(seconds) { ... }` to poll for a state.
   - A step that reads the system (Dock, processes) calls `app.requireAccessibility()` first;
     `AppSession` calls it itself in `window()` and `element(_:)`. A missing permission is
     NOT READ BACK, never a FAIL and never a PASS.
3. Add `Step(id: "R<n>", name: "<what the user sees>", run: <function>)` to `BaseSteps.all`.
   `main.swift` runs only `BaseSteps.all`: a step list in a new file runs only after
   `main.swift` adds it to `steps`. `_Steps/` holds at most 5 entries, one `_` entry.
4. Give every view the step reads an accessibility identifier (`nhetrinh.<name>`).
5. Machine rules: one app instance, at most 3 tabs loading, pages one after another.
   Capture only the app's own window, or the Dock item and a ring clamped to the Dock's own frame;
   never the screen. A capture goes to a temporary file, is read and deleted in the same step:
   no picture is kept in the repository, the report keeps only the numbers.
6. Run the checker, then `--steps R<n>` on the readback seat, then a full run.

## Report

Quote each step's line from `_LATEST.md`: the verdict and what it did and saw. A FAIL or a
NOT READ BACK gets its hub entries (`nhetrinh-hubs`).
