# NT-GAT-006 — R6 held a sidebar row across a reload — fix

id: NT-GAT-006
family: GAT
status: OBSERVED
date: 2026-11-16
source: _app/_Sources/NhetrinhReadback/_Steps/Fresh.swift (`Fresh.rowIndex(fromEnd:count:)`, `Fresh.retryingOnce`)
source: _app/_Sources/NhetrinhReadback/Driver/AppSession.swift `selectRow(fromEnd:)`
source: _app/_Sources/NhetrinhReadback/_Steps/_BaseSteps.swift `selectingRowShowsTab`
source: _app/Tests/NhetrinhReadbackTests/Steps/FreshTests.swift `rowIndexFromEnd` (6 cases), `retryingOnce` (5 cases)
links: fix=yes lesson=no evidence=yes toolgap=none

## Fix that holds

A step never holds an accessibility element across a change of the app. R6 selects a row with
`AppSession.selectRow(fromEnd:)`: it reads the sidebar rows right before acting and picks the row
by its index from the end of that fresh read. When the set cannot drive the app (a stale
element), it waits 0.3 s and does it once more, with a new read of the rows; a second failure
says "again after a fresh lookup". A step that ran and saw the app wrong (`StepError.fail`) is
not retried. Too few rows is a FAIL with the count, not an out-of-range crash.

## The wrong fixes

Wait longer before the first set: the second set still uses a row read before the first
selection, which reloads the table again. Retry on the held element: it stays invalid.
Retry without limit: a real failure of the app would hide behind the loop.

## Proof

`_app/scripts/test.sh` green with the new tests: `rowIndexFromEnd` and `retryingOnce` (one retry
on a stale element, none on a FAIL, the second error says it came after a fresh lookup).
Not proven: red first. The stale element needs the running app; no unit test reproduces -25202.
Not proven: R6 on the installed app. Not rebuilt or read back yet: the matemaster batches one
rebuild (signing identity set up by the headmate, R-2).
