---
name: nhetrinh-ship
description: "Ship one nhetrinh phase: one PR, CI green, readback PASS, self-merge, version bump in _app/scripts/VERSION, tag; the tag publishes a GitHub Release (release.yml), read back with R44 and R45."
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
4. Commit, then `_app/scripts/install/_install.sh`, then the full readback (`nhetrinh-readback`), so the
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
2. Tag the merge commit on `master` `v<version>` from `VERSION`, for example `v0.1.0`, and push the
   tag. Every tag `v*` publishes on GitHub (see "Release" below): a `v0.x` tag as a prerelease, never
   "latest"; `v1.0.0` and later as the full release (D26). Tag only what may be downloaded.
3. Entries whose fix is now on `master` with a cited proof move from OBSERVED to FIXED, in the
   entry, its `_INDEX.md` row and its TRIAGE row.

## Release (a tag `v*`, P8)

Only when the brief names the seat and the headmate asked for the release; a mate never tags.

1. `VERSION` holds the release's version (`1.0.0` for P8, D13), bumped on the phase branch and merged.
   `release.yml` refuses a tag that is not exactly `v` + `VERSION`.
2. `git tag v<version> <merge commit on master>`, then `git push origin v<version>`.
3. `.github/workflows/release.yml` runs: the tag check; `build.yml`'s own job on the tag (checker, its
   tests, `test.sh`, build, bundle and size checks, arm64 only), which uploads
   `nhetrinh-<version>-arm64.zip`; then the zip's SHA-256 (`.sha256`), the notes
   (`_app/scripts/install/release_notes.py <version>`, from `hubs/product/features/`) and the Release:
   a prerelease for 0.x, the full and "latest" release from 1.0.0 (`release_notes.py <version> --kind`).
   Watch it: `gh run watch` (or `gh run list --workflow release.yml`).
4. A macOS runner that is short or stuck: "Re-run failed jobs", or
   `gh workflow run release.yml -f tag=v<version>`. A re-run replaces the Release's files and notes;
   it never makes a second Release. A red run gets its hub entries (family `CIP`).
5. R44, on the seat, once the Release is up: `cd _app && swift run nhetrinh-readback --steps R44
   --release-url https://github.com/<owner>/<repo>/releases/download/v<version>/nhetrinh-<version>-arm64.zip`.
   It checks the SHA-256 and runs R1-R8 on the downloaded copy; PASS only when all 8 pass. R2 needs the
   granted readback app (NT-TG-003). The macOS first-open warning is not read back: check it by hand
   on a copy downloaded in a browser (README "The first open").
6. R45: install the release (`_app/scripts/install/_install.sh` from the tagged commit, or the
   downloaded `nhetrinh.app` copied to ~/Applications), then the full run `swift run nhetrinh-readback`
   (R1-R43; it writes `_LATEST.md`). Fill the 1.0.0 column of `hubs/product/rnd/LIGHTNESS_1_0.md`
   from R8, R38 and R44, and add the evidence rows.
7. P8 exits when R1-R45 PASS, CI and the release run are green, and every hub item is FIXED or a
   known limit in `README.md` (`M3_V1_RELEASE.md`).

## Report to the headmate

Say what each readback step did (`_PLAN.md` gate step 10), with the version and the CI result.
Say what was not read back. Never call a phase done without its readback PASS.
