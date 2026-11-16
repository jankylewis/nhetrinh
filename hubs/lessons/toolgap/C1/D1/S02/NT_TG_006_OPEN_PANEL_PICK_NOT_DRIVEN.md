# NT-TG-006 — Open panel pick not driven

id: NT-TG-006
family: GAT
status: OPEN
date: 2026-11-16
signature: picking a file in the panel: not read back
source: _app/_Sources/NhetrinhReadback/_Steps/Tabs/Pages/Basics/PanelSteps.swift (`fileInput`, R22)
source: hubs/product/plan/M2_REAL_SITES_WORK.md R22: "pick a fixture file; the page shows its name"
links: fix=no lesson=no evidence=no toolgap=NT-TG-006

## Gap

The open panel runs outside the app (the system's panel process): the probe can see it and press
Cancel, not pick a file. R22 PASSes with the pick said "not read back" in its line, so a broken
`completionHandler(panel.urls)` would pass (P3-REVIEW P4).

## Workaround

None yet. Ruling needed: R22 as now with the pick named unit-test-only (as R17's ⌘-click), with a unit
test of the completion through a test `WKOpenPanelParameters` (not tried), or the pick read back.
