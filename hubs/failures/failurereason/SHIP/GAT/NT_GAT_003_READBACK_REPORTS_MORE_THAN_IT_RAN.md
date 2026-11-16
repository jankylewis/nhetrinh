# NT-GAT-003 — Readback reports more than it ran

id: NT-GAT-003
family: GAT
status: OBSERVED
date: 2026-11-16
signature: verdict: PASS (0 of 0)
source: _app/_Sources/NhetrinhReadback/main.swift `Options` and the step filter (commit 2e05899)
source: _app/_Sources/NhetrinhReadback/Report.swift `text`, `exitCode`, `tilde` (commit 2e05899)
source: cross-review of commit 237332d in brief P0-PRF-2, 2026-11-16
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
| 6 | NT-GAT-004 (R2 icon match) | same family, its own mechanism |

## Mechanism

`Options` read flags in pairs and dropped what it did not know; an empty step set means "all".
`Report.text` printed PASS whenever nothing failed or was skipped, also for zero steps.
`tilde` replaced the home path as plain text, not as a whole path part.
The tests (NT-GAT-002) held one non-PASS verdict, always in the last step.

## Confirm

Read from the code at commit 2e05899 (not run): `--steps R9` selects no step, and the report then
prints `PASS (0 of 0)` and exits 0. The red-first tests of the fix show each instance.
