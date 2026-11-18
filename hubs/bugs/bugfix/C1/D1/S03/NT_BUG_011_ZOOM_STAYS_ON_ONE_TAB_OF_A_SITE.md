# NT-BUG-011 — The zoom stays on one tab of a site — fix

id: NT-BUG-011
family: UIX
status: OBSERVED
date: 2026-11-17
source: _app/Tests/NhetrinhTests/Page/ToolsReviewTests.swift `zoomReachesEveryLoadedTabOfTheHost` (P4P6-FIX-1)
links: fix=yes lesson=no evidence=no toolgap=none

## Change

`applyPrefs` calls `applyZoomToLoadedTabs` when the zoom map changes: every loaded tab with a host goes to its host's level; the selected tab's host comes from the tab's URL when the web view has none yet.

## Proof

Red on 96130c6 (2 issues), green with the fix. Not read back.
