# NT-BLD-002 — Release binary path guessed

id: NT-BLD-002
family: BLD
status: OBSERVED
date: 2026-11-16
signature: cp: .build/arm64-apple-macosx/release/Nhetrinh: No such file or directory
source: _app/scripts/_build.sh (copy step)
links: fix=yes lesson=no evidence=no toolgap=none

## Mechanism

The script hard-coded SwiftPM's output folder. `swift test` on this machine reported the target `arm64e-apple-macos14.0`, so the folder name differs.
Not proven: the exact folder SwiftPM used for the release build.

## Confirm

`swift build -c release --show-bin-path`.

## Fix

`_build.sh` reads the folder from `--show-bin-path` (scaffold, not yet on `master`).
