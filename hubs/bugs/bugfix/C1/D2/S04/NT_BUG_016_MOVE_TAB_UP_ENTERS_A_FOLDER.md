# NT-BUG-016 — Move Tab Up puts a root tab into a folder — fix

id: NT-BUG-016
family: TAB
status: OBSERVED
date: 2026-11-17
source: P7-FIX-1 on p7/prep (`moveTabStepsOneRow`)
links: fix=yes lesson=no evidence=no toolgap=none

## Change

Move Tab Up / Down use `Tree.step` on the selected tab's path; the menu items are on only when a step would move (`canMoveSelectedTab`).

## Proof

Core `aRootTabStepsAlongTheRoot`, `aFolderTabStepsOutAtItsEdge` red on a stub, green; app `moveTabStepsOneRow` and `moveTabItemIsOffWhenNothingMoves` fail when the old flat move is put back (a file-backup mutation), green with the fix. R14 (root tabs only) unchanged. Not read back.
