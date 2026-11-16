# NT-BUG-013 — A reopened tab lands in another folder — fix

id: NT-BUG-013
family: TAB
status: OBSERVED
date: 2026-11-17
source: P7-FIX-1 on p7/prep (`reopenPutsTheTabBackWhereItWas`)
links: fix=yes lesson=no evidence=no toolgap=none

## Change

`ClosedTab` keeps the tab's path and its folder's name; `Tree.reinsert` puts it back in the folder of that name (at its place, else wherever it is now) at its index, clamped; when no folder has that name, at the root where the folder's tabs went. A tab closed before P7 (no path) still uses the flat index.

## Proof

`reopenPutsTheTabBackWhereItWas` red on e0b91ff (4 of 5 cases), green; Core `aClosedTabComesBackWhereItWas`, `aClosedTabFindsItsFolderOrItsPlace` red on a stub, green. Not read back.
