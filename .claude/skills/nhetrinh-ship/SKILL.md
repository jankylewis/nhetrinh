---
name: nhetrinh-ship
description: "Ship one nhetrinh phase: one PR, CI green, readback PASS, self-merge, version bump in _app/scripts/VERSION, tag."
---

# nhetrinh-ship

One PR per phase; self-merge when CI is green and the readback passes (`DECISIONS.md` D12).
Version per phase: 0.1.0 (P0) to 0.8.0 (P7), then 1.0.0 (P8) (D13, `_PLAN.md` "Phases").
The matemaster merges and ships (`CLAUDE.md`). A mate never pushes, merges or touches `master`.

## Before the PR

1. The phase passed every gate step of `nhetrinh-develop` on its branch.
2. `_app/scripts/VERSION` holds the phase's version (one line, for example `0.1.0`).
   `_build.sh` writes it into `Info.plist` (`CFBundleShortVersionString`, `CFBundleVersion`)
   and the commit into `NHTCommit`. A `+` after the commit means files changed since it.
3. Local checks, one at a time:
   - `python3 _app/scripts/conventions/_check.py` prints `0 violations`.
   - `python3 -m unittest discover -s _app/scripts/conventions -p 'test_*.py'` is OK.
   - `nice -n 10 _app/scripts/test.sh` is all green.
   - `nice -n 10 _app/scripts/_build.sh` prints the bundle and its size.
4. Commit, then `_app/scripts/install.sh`, then the full readback (`nhetrinh-readback`), so the
   readback reads an app built from a clean commit (no `+`).
5. The readback verdict is `PASS (n of n)`. Commit `hubs/failures/evidence/readback/_LATEST.md`.
   FAIL, INCOMPLETE or NOT READ BACK does not ship.
6. Hubs in the same PR (`nhetrinh-hubs`): feature rows, entries, evidence rows.
7. In `hubs/product/plan/_PLAN.md`, set the phase Status to DONE with the verdict file cited,
   and the status line in its milestone file.

## The PR

- One PR per phase, from the phase branch to `master`.
- The body says, per readback step, what the readback did and saw (copy from `_LATEST.md`),
  and quotes the checker and test counts.
- CI (`.github/workflows/build.yml`) runs: the checker, the checker's tests, `test.sh`,
  `_build.sh`, the bundle checks, the 1 MB size budget, the readback build
  (`swift build -c release --product nhetrinh-readback`, not run: it needs Accessibility),
  and the bench tools compile (never run).
- Wait for CI green. A red CI gets its hub entries (family `CIP` when CI differs from local).

## Merge and tag

1. Self-merge the PR when CI is green and the readback is PASS.
2. Tag the merge commit on `master` `v<version>` from `VERSION`, for example `v0.1.0`
   (`M3_V1_RELEASE.md`: the release workflow runs on a tag `v*`).
3. Entries whose fix is now on `master` with a cited proof move from OBSERVED to FIXED, in the
   entry, its `_INDEX.md` row and its TRIAGE row.

## Report to the headmate

Say what each readback step did (`_PLAN.md` gate step 10), with the version and the CI result.
Say what was not read back. Never call a phase done without its readback PASS.
