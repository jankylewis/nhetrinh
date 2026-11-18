# NT-BUG-014 — Closing a tab selects a hidden one — fix

id: NT-BUG-014
family: TAB
status: OBSERVED
date: 2026-11-17
source: P7-FIX-1 on p7/prep (`closingTheSelectedTabSelectsAVisibleTab`)
links: fix=yes lesson=no evidence=no toolgap=none

## Change

`close(at:)` selects `Tree.nearestVisible(afterRemoving:)`. ⌃⇥ / ⌃⇧⇥ (ruling after P7-FIX-1) step through visible tabs only, round the ends (`Tree.visibleStep`); from a hidden tab to its visible neighbour; the items are off when no other visible tab exists.

## Proof

`closingTheSelectedTabSelectsAVisibleTab` red on e0b91ff, green; `controlTabSkipsACollapsedFolder` and Core `controlTabStepsThroughVisibleTabs` red on 9e6d1c4 (1 and 7 issues), green; Core `closingSelectsTheNearestVisibleTab` red on a stub, green. Not read back.
