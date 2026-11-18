# NT-BLD-002 — Release binary path guessed

id: NT-BLD-002
family: BLD
status: FIXED
date: 2026-11-16
signature: cp: .build/arm64-apple-macosx/release/Nhetrinh: No such file or directory
source: _app/scripts/_build.sh:9 (`BIN=$(swift build -c release --arch arm64 --show-bin-path)`)
observed: 2026-11-16, P0-HAR-1 seat: `swift build -c release --arch arm64 --show-bin-path` printed `_app/.build/out/Products/Release`, not the hard-coded folder
links: fix=yes lesson=no evidence=no toolgap=none

## Mechanism

The script hard-coded SwiftPM's output folder `.build/arm64-apple-macosx/release`. SwiftPM on
this machine puts the release binary in another folder (`.build/out/Products/Release`, observed
above), so the copy step failed.
Not proven: which SwiftPM version or setting moves the folder.

## Confirm

`swift build -c release --arch arm64 --show-bin-path` from `_app/`.

## Fix

`_build.sh` asks SwiftPM for the folder (`--show-bin-path`, line 9) and copies `$BIN/Nhetrinh`.
Status stays OBSERVED until the fix is on `master`.
