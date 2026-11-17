# NT-BUG-004 — Closing another row moves the selection

id: NT-BUG-004
family: UIX
status: OBSERVED
date: 2026-11-16
signature: the selected tab stays
source: _app/_Sources/_Nhetrinh/_Browser/_Window/BrowserWindowController+Tabs.swift on master 7176264 (`close(at:)`)
source: _app/Tests/NhetrinhTests/TabHandlingTests.swift `rowMenuClosesThatRowAndReopenBringsItBack` (P2-BUILD-1)
observed: found while building P2 (code read, then a test); no user report
links: fix=yes lesson=no evidence=no toolgap=none
cause: NT-UIX-002

## Steps

Open 3 tabs, select row 3. Right-click row 1 and choose Close Tab.

Expected: row 1 closes; the tab of row 3 stays selected (now row 2).
Actual (master 7176264, from the code): the tab now in row 1 (the old row 2) is selected and loads.
P2 adds three more ways to close a row that is not selected (close button, middle click, R13).

Old behaviour not run on the installed app (from the code). The fix read back: R13 PASS 22:34 (`_LATEST.md`).
