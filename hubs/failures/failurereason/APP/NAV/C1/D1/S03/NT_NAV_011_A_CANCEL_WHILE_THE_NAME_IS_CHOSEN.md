# NT-NAV-011 — A cancel while the name is chosen

id: NT-NAV-011
family: NAV
status: OBSERVED
date: 2026-11-17
signature: isRunning(entry)
source: _app/_Sources/_Nhetrinh/_Browser/Page/Outside/_Downloads.swift (`decideDestinationUsing`)
source: nhetrinh_wt/REVIEW_P5.md (P5-REVIEW, outside the repository)
links: fix=yes lesson=no evidence=no toolgap=none

## Mechanism

The naming continuation captured the entry: a Cancel after naming started (the queue also waits on macOS's first Downloads prompt) left the name reserved for the launch and handed WebKit a destination for a cancelled row. Read from the code; a Cancel before WebKit asks holds (test, 2 of 2, not kept).

## Confirm

From the code (P5-REVIEW F7). Not reproduced: the window cannot be held open by a test.
