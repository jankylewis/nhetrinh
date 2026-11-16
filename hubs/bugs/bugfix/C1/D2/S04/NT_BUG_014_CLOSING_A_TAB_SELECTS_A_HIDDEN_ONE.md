# NT-BUG-014 — Closing a tab selects a hidden one — fix

id: NT-BUG-014
family: TAB
status: OBSERVED
date: 2026-11-17
source: P7-FIX-1 on p7/prep (`closingTheSelectedTabSelectsAVisibleTab`)
links: fix=yes lesson=no evidence=no toolgap=none

## Change

`close(at:)` selects `Tree.nearestVisible(afterRemoving:)`. ⌃⇥ / ⌃⇧⇥ still walk every tab, hidden ones too (not in the ruling).

## Proof

`closingTheSelectedTabSelectsAVisibleTab` red on e0b91ff, green; Core `closingSelectsTheNearestVisibleTab` red on a stub, green. Not read back.
