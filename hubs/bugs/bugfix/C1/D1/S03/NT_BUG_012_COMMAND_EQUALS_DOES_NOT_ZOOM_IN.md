# NT-BUG-012 — Command-equals does not zoom in — fix

id: NT-BUG-012
family: UIX
status: OBSERVED
date: 2026-11-17
source: _app/Tests/NhetrinhTests/Page/ToolsReviewTests.swift `zoomInHasBothKeys` (P4P6-FIX-1)
links: fix=yes lesson=no evidence=no toolgap=none

## Change

A hidden View > Zoom In item with the key `=`, `allowsKeyEquivalentWhenHidden`; the probe's shortcut list skips hidden items, so it still reads `View > Zoom In: ⌘+`.

## Proof

`zoomInHasBothKeys` red on 96130c6, green with the fix. The key press itself is not read back.
