# NT-BUG-009 — The find answer is shown on another tab — fix

id: NT-BUG-009
family: UIX
status: OBSERVED
date: 2026-11-17
source: _app/Tests/NhetrinhTests/Page/ToolsReviewTests.swift `anAnswerIsNotCarriedToAnotherTab` (P4P6-FIX-1)
links: fix=yes lesson=no evidence=no toolgap=none

## Change

`select` clears the find bar's answer.

## Proof

Red on 96130c6 (2 issues), green with the fix (P4P6-FIX-1, test.sh). Not read back.
