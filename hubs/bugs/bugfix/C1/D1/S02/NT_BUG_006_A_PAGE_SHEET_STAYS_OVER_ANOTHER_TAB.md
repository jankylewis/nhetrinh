# NT-BUG-006 — A page's sheet stays over another tab — fix

id: NT-BUG-006
family: UIX
status: OBSERVED
date: 2026-11-16
source: _app/_Sources/_Nhetrinh/_Browser/Page/_Sheets.swift (`endSheets(of:)`, `keep`, `forget`, P3-FIX-1)
source: _app/Tests/NhetrinhTests/Page/_SheetGapsTests.swift `aSheetNeverOutlivesOrHidesTheTabThatAsked`
links: fix=yes lesson=no evidence=no toolgap=none

## Change

The window keeps each page's sheet with that page's web view. Closing or leaving the tab ends it
with no button pressed (`hubs/failures/failfix/APP/UIX/C1/D1/S01/NT_UIX_004_A_SHEET_OUTLIVED_ITS_PAGE.md`).

## Proof

Red first on 1d391d9 (both cases, P3-REVIEW); green with the fix (P3-FIX-1, test.sh); red again
under a mutation that removes the two calls in `select` and `close(at:)`. Not read back. Not on master.
