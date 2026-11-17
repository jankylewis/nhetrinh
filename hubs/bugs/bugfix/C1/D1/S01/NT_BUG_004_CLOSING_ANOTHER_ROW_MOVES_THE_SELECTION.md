# NT-BUG-004 — Closing another row moves the selection — fix

id: NT-BUG-004
family: UIX
status: OBSERVED
date: 2026-11-16
source: _app/_Sources/_Nhetrinh/_Browser/_Window/BrowserWindowController+Tabs.swift (`close(at:)`, P2-BUILD-1)
source: _app/Tests/NhetrinhTests/TabHandlingTests.swift `rowMenuClosesThatRowAndReopenBringsItBack`
links: fix=yes lesson=no evidence=no toolgap=none

## Change

`close(at:)` selects another tab only when the selected tab closes. A row above the selected
one shifts the selection index by one; the selected tab and its page stay
(`hubs/failures/failfix/APP/UIX/C1/D1/S01/NT_UIX_002_CLOSE_SELECTED_THE_CLOSED_INDEX.md`).

## Proof

Red first: the test (rows 1, 2, 3 closed through the row's menu, row 3 selected) failed on the old
`close(at:)` in the first P2 test run; green with the fix. Checked again by a mutation that restores
the old path: red (P2-BUILD-1, test.sh).
Read back: R13 PASS 22:34, `row 1's menu > Close Tab: 2 rows [...], the selected tab kept` (`_LATEST.md`, build eac0ce9+). Not on master.
