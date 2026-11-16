# NT-GAT-003 — Readback reports more than it ran

id: NT-GAT-003
family: GAT
status: OBSERVED
date: 2026-11-16
signature: verdict: PASS (0 of 0)
source: _app/_Sources/NhetrinhReadback/main.swift `Options` and the step filter (commit 2e05899)
source: _app/_Sources/NhetrinhReadback/Report.swift `text`, `exitCode`, `tilde` (commit 2e05899)
source: _app/Tests/NhetrinhReadbackTests/OptionsTests.swift `badCommandLineIsAUsageError`, ReportTests.swift (commit 4ee85bf)
source: _app/Tests/NhetrinhReadbackTests/OptionsTests.swift `repeatedFlagIsAUsageError` (commit 90b8cab)
source: _app/Tests/NhetrinhReadbackTests/OptionsTests.swift `usageErrorNamesNoPersonalPath` (commit 88a9953, red)
links: fix=yes lesson=no evidence=no toolgap=none

## Family

The readback's verdict or evidence says more than it saw, while its tests pass. Known instances:

| # | Instance | What went wrong |
|---|---|---|
| 1 | `--step R8` (typo), `R8` without a flag | ignored: every step ran and `_LATEST.md` was overwritten |
| 2 | `--steps` with no value, or an empty value | the same full run; a test asserted this as right |
| 3 | `--steps R9` (no such step) | no step ran; verdict `PASS (0 of 0)`, exit 0 |
| 4 | `tilde` on `/Users/<name>2/...` | replaced the home prefix inside another folder name: `~2/...` |
| 5 | exit code with FAIL and NOT READ BACK in one run | logic right, but no test held it; FAIL-first order untested |
| 6 | `--steps R1 --steps R2`, `--app a --app b` | the last value won silently: only R2 ran |
| 7 | `--evidence <home>/elsewhere` | the usage error echoed a path under the home folder to stderr and the app log (law 8) |
| 8 | NT-GAT-004 (R2 icon match) | same family, its own mechanism |

## Mechanism

`Options` read flags in pairs and dropped what it did not know; an empty step set means "all".
A flag given twice overwrote its first value (commit 4ee85bf).
`Report.text` printed PASS whenever nothing failed or was skipped, also for zero steps.
`tilde` replaced the home path as plain text, not as a whole path part.
`UsageError` messages quoted the given path and went to stderr without `tilde`.
The tests (NT-GAT-002) held one non-PASS verdict, always in the last step.

## Confirm

Read from the code at commit 2e05899 (not run): `--steps R9` selects no step, and the report then
prints `PASS (0 of 0)` and exits 0. The red-first tests of the fix show each instance:
`_app/scripts/test.sh` at commit 90b8cab records 2 issues in `repeatedFlagIsAUsageError` (instance 6).
At commit 88a9953 `usageErrorNamesNoPersonalPath` is red (instance 7).
