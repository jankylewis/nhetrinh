# NT-BUG-006 — A page's sheet stays over another tab

id: NT-BUG-006
family: UIX
status: FIXED
date: 2026-11-16
found_by: development (P3-REVIEW)
signature: the sheet is still shown, the answer none
source: _app/_Sources/_Nhetrinh/_Browser/Page/_Sheets.swift on p3/pages 1d391d9 (`ask`)
source: _app/Tests/NhetrinhTests/Page/_SheetGapsTests.swift `aSheetNeverOutlivesOrHidesTheTabThatAsked` (P3-REVIEW)
observed: found by the P3 adversarial review (code read, then a test); no user report
links: fix=yes lesson=no evidence=no toolgap=none
cause: NT-UIX-004

## Steps

A page asks `confirm("…")`: its sheet is on the window. Press ⌘W, or ⌃⇥.

Expected: the sheet goes with its page; the page gets an answer (Cancel).
Actual (1d391d9, from the test): the next tab is shown and the sheet stays over it, asking for a page
that is gone or hidden; the page gets no answer until the user presses a button.

Not run on the installed app (from the code and the unit test). Not on master.

Status FIXED (2026-11-27): the fix's test is on `master`, and its phase passed the full readback of
2026-11-17 13:19 (`hubs/product/plan/_PLAN.md`).
