# NT-BUG-010 — Clear All keeps the zoomed sites

id: NT-BUG-010
family: UIX
status: FIXED
date: 2026-11-17
found_by: development (P4/P6 review)
signature: clearAllForgetsTheZoom
source: _app/_Sources/_Nhetrinh/UI/Settings/SettingsHub+Actions.swift on p6/memory 96130c6 (`askToClear`)
source: _app/Tests/NhetrinhTests/Page/ToolsReviewTests.swift `clearAllForgetsTheZoom`
observed: found by the P4/P6 adversarial review (code read, then a test); no user report
links: fix=yes lesson=no evidence=no toolgap=none
cause: no failure reason filed: the mechanism is in the fix entry

## Steps

Zoom a site, then Settings Hub > Clear Website Data… > Clear All.

Expected: the site's zoom goes too (ruling F6): `prefs.json` keeps no list of sites.
Actual: from the code: the zoom map, a list of zoomed hosts, stays in `prefs.json` (F6).

Status FIXED (2026-11-27): the fix's test is on `master`, and its phase passed the full readback of
2026-11-17 13:19 (`hubs/product/plan/_PLAN.md`).
