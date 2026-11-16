# NT-GAT-006 — R6 held a sidebar row across a reload

id: NT-GAT-006
family: GAT
status: OBSERVED
date: 2026-11-16
signature: R6 NOT READ BACK: cannot set AXSelected (accessibility error -25202)
source: _app/_Sources/NhetrinhReadback/_Steps/_BaseSteps.swift `selectingRowShowsTab` (commit 4d3902f: rows read once, then set twice)
source: _app/_Sources/_Nhetrinh/_Browser/_Window/BrowserWindowController+Tabs.swift `observe(_:for:)` (title, url, canGoBack, canGoForward call `refreshChrome`)
source: _app/_Sources/_Nhetrinh/UI/_SidebarView.swift `update(titles:loaded:selected:)` (`table.reloadData()`)
source: hubs/failures/evidence/readback/_LATEST.md (branch `p0/harness-docs`, run 2026-11-16 19:27, app commit fba7d9e)
observed: R1, R3, R4, R5, R7, R8 PASS in the same run; Accessibility was granted
links: fix=yes lesson=no evidence=yes toolgap=none

## Mechanism

-25202 is `kAXErrorInvalidUIElement`: the element no longer exists in the app. R6 read the sidebar
rows once, after the address bar showed example.org, and kept them for two selections. Every
title, URL or back/forward change of a page calls `refreshChrome`, and that calls `reloadData` on
the sidebar table: the rows are made again, and a row element read before is invalid. The title
of example.org arrives after its URL, and the first selection itself changes the address and the
title, so a held row can go stale before either `AXSelected` set.

Not proven: which of the two sets failed in the 19:27 run, and which change reloaded the table
between the read and the set. The report holds only the error.

## Confirm

1. `grep -n reloadData _app/_Sources/_Nhetrinh/UI/_SidebarView.swift` and the observers above.
2. A readback step that reads `AXRows`, waits for a navigation, then sets `AXSelected` on a row
   it read before: -25202 when the title changed in between.
