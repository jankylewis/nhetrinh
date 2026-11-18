# NT-BLD-002 — Release binary path guessed — fix

id: NT-BLD-002
family: BLD
status: FIXED
date: 2026-11-16
source: _app/scripts/_build.sh:8-13
links: fix=yes lesson=no evidence=no toolgap=none

## Fix that holds

Build with `swift build -c release --arch arm64 --product Nhetrinh`, then read the folder with
the same flags plus `--show-bin-path`, and copy `$BIN/Nhetrinh`. Never hard-code `.build/...`.

## Wrong fixes

1. Hard-code the new folder: it moves again with the SwiftPM version or target triple.

## Proof

2026-11-16, P0-HAR-1 seat, branch `p0/harness-docs`: `nice -n 10 _app/scripts/_build.sh` ended
with `build/nhetrinh.app 540K`; the CI bundle checks (`plutil -lint`, `codesign --verify --strict`,
both icon files) passed. CI: below.

## Proof on master (0f99aee)

CI run 43885459211 (PR #1, head 402adec, the same tree as master 0f99aee): `_build.sh` printed `build/nhetrinh.app 540K`, the bundle checks passed.
