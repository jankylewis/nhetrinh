# NT-GAT-002 — Readback tool had no tests

id: NT-GAT-002
family: GAT
status: OBSERVED
date: 2026-11-16
signature: no testTarget depends on NhetrinhReadback
source: P0 brief P0-HAR-3, 2026-11-16 ("The readback tool has no tests; a test that cannot fail is a defect")
source: commit 230200c (`_app/Package.swift`: the `NhetrinhReadback` target, no test target for it)
links: fix=yes lesson=yes evidence=no toolgap=none

## Mechanism

The readback tool decides PASS, FAIL and NOT READ BACK for every phase. Its own logic was not
tested: the R2 pass rule (`IconMatch`), the verdict counts and exit code (`Report`), the
command line (`Options`). A defect there could turn a broken app into a PASS.
The latest readback (`hubs/failures/evidence/readback/_LATEST.md`) has R2 as NOT READ BACK, so
`IconMatch` never ran on a real Dock either.
Not proven then: that this logic had a defect. The first tests passed on their first run.
Proven later by a cross-review: NT-GAT-003 (command line, report) and NT-GAT-004 (R2).

## Confirm

`grep -n testTarget _app/Package.swift`: a test target must name `NhetrinhReadback`.

## Fix

Test target `NhetrinhReadbackTests` (`_app/Tests/NhetrinhReadbackTests/`).
