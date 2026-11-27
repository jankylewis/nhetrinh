# NT-BUG-015 — Folders are lost with the last tab

id: NT-BUG-015
family: TAB
status: FIXED
date: 2026-11-17
found_by: development (P7 review)
signature: foldersWithoutATabAreKept
source: _app/_Sources/NhetrinhCore/Tabs/Lifecycle/Tree/TreeSession.swift on p7/prep e0b91ff (`load`)
observed: found by the P7 adversarial review (code read, then a test); no user report
links: fix=yes lesson=no evidence=no toolgap=none
cause: no failure reason filed: the mechanism is in the fix entry

## Steps

Make a folder, close every tab (the app quits), launch again.

Expected: the folders are back, empty, with one home tab at the root (ruling P3).
Actual: from the code: one home tab and no folder: a session with no tab was replaced by `.home`.

Status FIXED (2026-11-27): the fix's test is on `master`, and its phase passed the full readback of
2026-11-17 13:19 (`hubs/product/plan/_PLAN.md`).
