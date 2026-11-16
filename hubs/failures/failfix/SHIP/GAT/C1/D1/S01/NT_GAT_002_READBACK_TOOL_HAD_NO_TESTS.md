# NT-GAT-002 — Readback tool had no tests — fix

id: NT-GAT-002
family: GAT
status: OBSERVED
date: 2026-11-16
source: commit 237332d (`_app/Package.swift`, `_app/Tests/NhetrinhReadbackTests/`)
links: fix=yes lesson=yes evidence=no toolgap=none

## Fix that holds

Test target `NhetrinhReadbackTests`, `@testable import NhetrinhReadback`, parameterized:
1. `_IconMatchTests.swift`: drawn Dock captures. The icon alone passes; the same icon smaller
   on a dark rounded tile fails; a blank capture fails.
2. `ReportTests.swift`: all pass, one fail, one not read back: exit code, verdict line, step row.
3. `OptionsTests.swift`: 5 command lines: the app, the steps, and whether evidence is kept.

The R2 rule moved into `IconMatch.showsBareIcon`, so R2 and the test use one rule.
`_app/scripts/test.sh` runs these tests, locally and in CI.

## Wrong fixes

1. Count on the readback runs to check the tool: R2 has not run yet (NOT READ BACK in
   `_LATEST.md`), so its rule was never used.

## Proof

P0-HAR-3 seat, 2026-11-16: `nice -n 10 _app/scripts/test.sh` ended with
`✔ Test run with 5 tests in 0 suites passed after 0.848 seconds.` With the R2 rule set to
`agreement >= 0.0` for one run, the icon test failed: `with 3 test cases failed ... with 2 issues`
(dark tile, blank). Not on `master`.
