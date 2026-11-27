# NT-BUG-016 — Move Tab Up puts a root tab into a folder

id: NT-BUG-016
family: TAB
status: FIXED
date: 2026-11-17
found_by: development (P7 review)
signature: moveTabStepsOneRow
source: _app/_Sources/NhetrinhCore/Tabs/Lifecycle/Tree/TreeFlat.swift on p7/prep e0b91ff (`moveTab(fromFlat:toFlat:)`)
observed: found by the P7 adversarial review (code read, then a test); no user report
links: fix=yes lesson=no evidence=no toolgap=none
cause: no failure reason filed: the mechanism is in the fix entry

## Steps

Folder A (a1, a2), then a root tab r selected. Tabs > Move Tab Up.

Expected: r goes above A, whole (ruling P4: one row within its container; a root tab never enters a folder by Move; at a folder's edge a tab steps out to the root next to the folder).
Actual: from the code: r went inside A, between a1 and a2 (moved by flat index with the insert rule).

Status FIXED (2026-11-27): the fix's test is on `master`, and its phase passed the full readback of
2026-11-17 13:19 (`hubs/product/plan/_PLAN.md`).
