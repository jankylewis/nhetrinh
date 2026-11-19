# NT-BUG-025 — After Reset profile, no visit is kept until a relaunch

id: NT-BUG-025
family: TAB
status: OBSERVED
date: 2026-11-19
signature: history: disk I/O error after Reset profile
source: _app/Tests/NhetrinhTests/SignIns/ProfileWiringTests.swift (`resetEmptiesTheHistoryAndKeepsRecording`)
observed: only in the trial merge of P10 into P11 (`p12/combine`); no build with both was ever installed
found_by: development (matemaster review of the P10 + P11 merge, 2026-11-19)
links: fix=yes lesson=no evidence=no toolgap=none

## Steps

In a build with P10 and P11: visit a page, Settings Hub > Reset profile… > Reset, visit another page.

Expected: the history is empty after the reset, and the new visit is kept.
Actual (red test, before the fix): the store P11 opened stays open on the deleted `history.sqlite`; the next
record fails with SQLite's `disk I/O error` (its `-wal` and `-shm` were deleted too), until a relaunch.

## Cause

`HistoryKeeper` opens the store once and keeps it; `ProfileReset.empty` deletes every file of the folder under it.

## Fix

`resetProfile` closes the store first (`HistoryKeeper.close`); the next use opens a new file. Red test first
(`Caught error: .sqlite(code: 10, message: "disk I/O error")`), green after; full `test.sh` rc 0. Not on
`master`, not read back.
