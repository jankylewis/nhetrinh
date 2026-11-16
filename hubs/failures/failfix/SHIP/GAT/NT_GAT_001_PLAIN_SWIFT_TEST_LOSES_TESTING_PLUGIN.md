# NT-GAT-001 — Plain swift test loses the Swift Testing plugin — fix

id: NT-GAT-001
family: GAT
status: OBSERVED
date: 2026-11-16
source: _app/scripts/test.sh
source: .github/workflows/build.yml (step "Unit tests")
links: fix=yes lesson=yes evidence=no toolgap=none

## Fix that holds

`_app/scripts/test.sh` gives the Swift Testing plugin path to the compiler on every run
(`-external-plugin-path`, from `xcode-select -p`). If that folder is missing, it falls back to
plain `swift test`. Extra arguments go to `swift test`. CI and every skill call `test.sh`.

## Wrong fixes

1. Run plain `swift test` again until it passes: it hides the failure, and 2 of 4 runs fail.

## Proof

Matemaster brief P0-HAR-1: `test.sh` passed 8 of 8 runs on the machine where plain
`swift test` failed 2 of 4. Not proven on CI yet: no CI run of `test.sh` is cited. Not on `master`.
