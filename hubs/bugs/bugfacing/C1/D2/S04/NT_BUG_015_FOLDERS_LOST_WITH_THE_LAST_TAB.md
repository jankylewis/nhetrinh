# NT-BUG-015 — Folders are lost with the last tab

id: NT-BUG-015
family: TAB
status: OBSERVED
date: 2026-11-17
signature: foldersWithoutATabAreKept
source: _app/_Sources/NhetrinhCore/Tabs/Lifecycle/Tree/TreeSession.swift on p7/prep e0b91ff (`load`)
observed: found by the P7 adversarial review (code read, then a test); no user report
links: fix=yes lesson=no evidence=no toolgap=none
cause: no failure reason filed: the mechanism is in the fix entry

## Steps

Make a folder, close every tab (the app quits), launch again.

Expected: the folders are back, empty, with one home tab at the root (ruling P3).
Actual: from the code: one home tab and no folder: a session with no tab was replaced by `.home`.
