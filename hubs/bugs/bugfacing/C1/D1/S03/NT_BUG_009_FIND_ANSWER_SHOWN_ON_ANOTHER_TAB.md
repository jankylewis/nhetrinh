# NT-BUG-009 — The find answer is shown on another tab

id: NT-BUG-009
family: UIX
status: OBSERVED
date: 2026-11-17
found_by: development (P4/P6 review)
signature: anAnswerIsNotCarriedToAnotherTab
source: _app/_Sources/_Nhetrinh/_Browser/_Window/BrowserWindowController+Tabs.swift on p6/memory 96130c6 (`select`)
source: _app/Tests/NhetrinhTests/Page/ToolsReviewTests.swift `anAnswerIsNotCarriedToAnotherTab`
observed: found by the P4/P6 adversarial review (code read, then a test); no user report
links: fix=yes lesson=no evidence=no toolgap=none
cause: no failure reason filed: the mechanism is in the fix entry

## Steps

Find a word on tab A (Not found), then select tab B.

Expected: the bar shows no answer for B until B is searched.
Actual: from the code: B shows "Not found" (the probe reads `not found`) for a search it never ran (F5).
