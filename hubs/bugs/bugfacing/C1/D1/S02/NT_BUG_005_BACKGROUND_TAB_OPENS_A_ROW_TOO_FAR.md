# NT-BUG-005 — Background tab opens a row too far

id: NT-BUG-005
family: UIX
status: OBSERVED
date: 2026-11-16
found_by: development (P2-REVIEW)
signature: closingARowKeepsTheBackgroundSlotInPlace
source: _app/_Sources/_Nhetrinh/_Browser/_Window/BrowserWindowController+Tabs.swift on p2/sidebar cc8affe (`close(at:)`)
source: _app/Tests/NhetrinhTests/Tabs/ReviewGapsTests.swift `closingARowKeepsTheBackgroundSlotInPlace` (P2-REVIEW)
observed: found by the P2 adversarial review (code read, then a test); no user report
links: fix=yes lesson=no evidence=no toolgap=none
cause: NT-UIX-003

## Steps

Open 3 tabs, select row 1. ⌘-click a link: a background tab opens as row 2. Close that row (its
button, its menu or a middle click). ⌘-click another link.

Expected: the new background tab is row 2, right after the selected tab.
Actual (cc8affe, from the test): it is row 3, after the tab that was row 3 before. The same when a
row above the selected tab closes: the next background tab skips one row.

Not run on the installed app (from the code and the unit test). Not on master.
