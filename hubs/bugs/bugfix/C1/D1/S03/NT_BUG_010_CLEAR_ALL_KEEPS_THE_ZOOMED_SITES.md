# NT-BUG-010 — Clear All keeps the zoomed sites — fix

id: NT-BUG-010
family: UIX
status: OBSERVED
date: 2026-11-17
source: _app/Tests/NhetrinhTests/Page/ToolsReviewTests.swift `clearAllForgetsTheZoom` (P4P6-FIX-1)
links: fix=yes lesson=no evidence=no toolgap=none

## Change

Core `ClearRange` maps the sheet's buttons (Cancel, Clear Last Hour, Clear All) to a date and says whether the per-site settings go; `SettingsHub.clear` removes the website data and, for Clear All, `Prefs.forgetSites()`; loaded tabs go back to 100 %.

## Proof

`ClearRangeTests`, `forgetSitesKeepsTheAppSettings`, `clearAllForgetsTheZoom` red first, green with the fix. R30 still presses Clear All; it cannot tell the two ranges apart (NT-GAT-011): the mapping is unit-tested. Not read back.
