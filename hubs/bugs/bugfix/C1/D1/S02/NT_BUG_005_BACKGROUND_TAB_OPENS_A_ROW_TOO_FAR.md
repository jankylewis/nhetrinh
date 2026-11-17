# NT-BUG-005 — Background tab opens a row too far — fix

id: NT-BUG-005
family: UIX
status: OBSERVED
date: 2026-11-16
source: _app/_Sources/_Nhetrinh/_Browser/_Window/BrowserWindowController+Tabs.swift (`close(at:)`, P2-FIX-1)
source: _app/Tests/NhetrinhTests/Tabs/ReviewGapsTests.swift `closingARowKeepsTheBackgroundSlotInPlace`
links: fix=yes lesson=no evidence=no toolgap=none

## Change

`close(at:)` moves the background slot up by one when the closed row was above it
(`hubs/failures/failfix/APP/UIX/C1/D1/S01/NT_UIX_003_CLOSE_LEFT_THE_BACKGROUND_SLOT.md`).

## Proof

Red first: 2 of the test's 3 cases failed on cc8affe (P2-REVIEW, test.sh); the third case (a row
below the slot closes) passed, so the test tells good from bad. Green with the fix (P2-FIX-1). Red
again under a mutation that removes the shift; restored from a file copy.
Not read back: no readback step closes a row between two background tabs. Not on master.
