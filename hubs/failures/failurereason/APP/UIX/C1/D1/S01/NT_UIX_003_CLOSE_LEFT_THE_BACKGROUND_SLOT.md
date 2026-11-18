# NT-UIX-003 — Close left the background slot

id: NT-UIX-003
family: UIX
status: OBSERVED
date: 2026-11-16
found_by: development (P2-REVIEW F1)
signature: closingARowKeepsTheBackgroundSlotInPlace
source: _app/_Sources/_Nhetrinh/_Browser/_Window/BrowserWindowController+Tabs.swift on p2/sidebar cc8affe (`close(at:)`)
source: _app/_Sources/_Nhetrinh/_Browser/Handling/_TabHandling.swift (`openInBackground`, `backgroundSlot`)
links: fix=yes lesson=no evidence=no toolgap=none

## Mechanism

`backgroundSlot` is the index where the next background tab goes (after the selected tab and the
tabs opened from it). `select` and `moveTab` reset it; `close(at:)` removed a row but kept the
index. A closed row above the slot shifts every later row up by one, so the kept index pointed
one row past the run.

## Confirm

`ReviewGapsTests.closingARowKeepsTheBackgroundSlotInPlace` on cc8affe: the cases "the background
tab itself closed" and "a row before the selected closed" fail; "a row after the run closed" passes.
