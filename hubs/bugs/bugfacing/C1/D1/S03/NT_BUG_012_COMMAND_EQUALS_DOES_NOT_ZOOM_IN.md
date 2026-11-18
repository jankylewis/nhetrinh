# NT-BUG-012 — Command-equals does not zoom in

id: NT-BUG-012
family: UIX
status: OBSERVED
date: 2026-11-17
found_by: development (P4/P6 review)
signature: zoomInHasBothKeys
source: _app/_Sources/_Nhetrinh/UI/AppMenu.swift on p6/memory 96130c6 (View > Zoom In, key `+`)
source: _app/Tests/NhetrinhTests/Page/ToolsReviewTests.swift `zoomInHasBothKeys`
observed: found by the P4/P6 adversarial review (code read, then a test); no user report
links: fix=yes lesson=no evidence=no toolgap=none
cause: no failure reason filed: the mechanism is in the fix entry

## Steps

Press ⌘= (no Shift) on a keyboard where + needs Shift.

Expected: the page zooms in, as ⌘+ does.
Actual: not proven (no key was pressed on the app): AppKit matches the typed character, `=`, and Zoom In's key was `+` (F9).
