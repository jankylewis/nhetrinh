# NT-BUG-011 — The zoom stays on one tab of a site

id: NT-BUG-011
family: UIX
status: FIXED
date: 2026-11-17
found_by: development (P4/P6 review)
signature: zoomReachesEveryLoadedTabOfTheHost
source: _app/_Sources/_Nhetrinh/_Browser/Handling/FindAndZoom.swift on p6/memory 96130c6 (`setZoom`)
source: _app/Tests/NhetrinhTests/Page/ToolsReviewTests.swift `zoomReachesEveryLoadedTabOfTheHost`
observed: found by the P4/P6 adversarial review (code read, then a test); no user report
links: fix=yes lesson=no evidence=no toolgap=none
cause: no failure reason filed: the mechanism is in the fix entry

## Steps

Open a site in two tabs; View > Zoom In in one.

Expected: both tabs of the site show the new level (the level is kept per host).
Actual: from the code: the other tab kept its level until its next page load (F8).

Status FIXED (2026-11-27): the fix's test is on `master`, and its phase passed the full readback of
2026-11-17 13:19 (`hubs/product/plan/_PLAN.md`).
