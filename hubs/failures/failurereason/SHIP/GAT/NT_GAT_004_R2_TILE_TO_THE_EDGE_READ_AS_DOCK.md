# NT-GAT-004 — R2 takes a tile to the edge for the Dock

id: NT-GAT-004
family: GAT
status: OBSERVED
date: 2026-11-16
signature: R2 the Dock icon has no tile | PASS (with a tile as large as the Dock item)
source: _app/_Sources/NhetrinhReadback/Driver/IconMatch.swift `borderColour` (commit 2e05899)
source: probe test in a scratch copy, brief P0-PRF-2: icon at 70 % on such a tile gave agreement 0.959, scale 0.70
links: fix=yes lesson=no evidence=no toolgap=none

## Mechanism

R2 takes the Dock's colour from the median of the capture's whole border. A dark tile that
reaches the border covers most of it, so the tile became "the Dock": only the icon counted as
occupied, it matched its own shape, and R2 passed while the tile was there (NT-BUG-002 shape).
The tests had one tile case, inset 8 %, so the border stayed Dock-coloured.
Not proven: that the real Dock capture has the tile at its edge (R2 has never run: no permission).

## Confirm

Draw a rounded dark tile as large as the capture, the icon at 70-80 % on it: `showsBareIcon` is true.
