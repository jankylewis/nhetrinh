# NT-GAT-001 — Plain swift test loses the Swift Testing plugin

id: NT-GAT-001
family: GAT
status: FIXED
date: 2026-11-16
found_by: self-test (plain `swift test` red in 2 of 4 runs, P0-HAR-1)
signature: error: plugin for module 'TestingMacros' not found
source: _app/scripts/test.sh (header comment, the `-external-plugin-path` line)
source: matemaster brief P0-HAR-1, 2026-11-16 (the run counts below)
observed: plain `swift test` (Command Line Tools, no Xcode) failed 2 of 4 runs with the signature; `_app/scripts/test.sh` passed 8 of 8 runs
observed: `swift test -v` of a failing run: the compile command of the test target had no plugin flag
links: fix=yes lesson=yes evidence=no toolgap=none

## Mechanism

With Command Line Tools only, SwiftPM sometimes leaves the Swift Testing macro plugin path out
of the compile command of the test target. The `@Test` macros then do not expand and the build
fails with the signature.
Not proven: why SwiftPM leaves the path out on some runs and not on others.

## Confirm

1. `swift test -v` from `_app/` on a red run.
2. In the compile command of `NhetrinhCoreTests`, look for `-external-plugin-path` or
   `-plugin-path` with `host/plugins/testing`. A red run has neither.

## Fix

Run the tests only with `_app/scripts/test.sh`. It passes
`-Xswiftc -external-plugin-path -Xswiftc "<tools>/usr/lib/swift/host/plugins/testing#<tools>/usr/bin/swift-plugin-server"`
on every run, where `<tools>` is `xcode-select -p`. CI calls `test.sh` too.
