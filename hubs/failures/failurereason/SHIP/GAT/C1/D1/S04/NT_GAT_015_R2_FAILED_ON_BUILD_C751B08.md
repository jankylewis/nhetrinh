# NT-GAT-015 — R2 failed on build c751b08

id: NT-GAT-015
family: GAT
status: OBSERVED
date: 2026-11-17
found_by: readback (R2 FAIL, full readback 2026-11-17 13:19)
signature: R2 FAIL the Dock item does not show the bare icon: silhouette agreement 90 %, icon at 94 % of the Dock item
signature: R2 FAIL the Dock item does not show the bare icon: silhouette agreement 80 %, icon at 100 % of the Dock item
source: hubs/failures/evidence/readback/_LATEST.md (full run 13:19, build c751b08: R2 FAIL)
source: _app/Tests/NhetrinhReadbackTests/Fixtures/_R2_1357_ITEM.png (the 13:57 R2 run, `--keep-capture`, cropped)
observed: 13:57, R2 alone, kept capture outside the repository: agreement 0.805, scale 1.00, background 42 76 107; item x 13.6 y 467.0 w 34 h 22 pt, Dock x 10 y 197 w 34 h 814 pt (left, tilesize 20, magnification on), capture x 10 y 462 w 34 h 33 pt (68 x 66 px)
links: fix=yes lesson=no evidence=yes toolgap=NT-TG-001

## Mechanism

A readback bug, not the app. The kept 13:57 PNG shows the bare icon, no tile. R2 captured the item
grown by a 6 pt ring (NT-GAT-004) and read the Dock's colour per line across the Dock from that
ring, before and after the item along the Dock (NT-GAT-007). On a 20 pt Dock the neighbour items
touch the item: the ring above and below held slices of them (rows 0-7 and 56-65 of 66 px), so on
the lines through the icon the "Dock colour" was a neighbour's colour and Dock pixels read as
occupied. The scored square also took in the 6 px past the Dock's visible edge (columns 57-63 of
the 44 px square: a strip that is not Dock colour on the whole item length). The running dot was
in the capture, left of the item. Together: 80.5 %.
The 13:19 FAIL (90 %) had no kept capture: not proven that it is the same mechanism; the same Dock
settings were in place (`RCA_P8_R2` outside the repository: tilesize 20, magnification on).

## Confirm

Old measurement on 13:57-like drawn captures with touching neighbours (`DockAxisTests`
`r2JudgesTheIconNotItsNeighbours`): the bare icon fails on a left, a bottom and a right Dock.
The 13:57 crop (`_IconMatchTests` `r2JudgesThe1357ItemOnItsOwnFrame`): 97.0 % with the fix.

## Fix

`hubs/failures/failfix/SHIP/GAT/C1/D1/S04/NT_GAT_015_R2_FAILED_ON_BUILD_C751B08.md`.
