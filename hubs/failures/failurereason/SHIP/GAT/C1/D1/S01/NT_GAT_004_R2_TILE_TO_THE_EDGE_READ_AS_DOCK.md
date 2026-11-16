# NT-GAT-004 — R2 takes a tile to the edge for the Dock

id: NT-GAT-004
family: GAT
status: OBSERVED
date: 2026-11-16
signature: R2 the Dock icon has no tile | PASS (with a tile as large as the Dock item)
source: _app/_Sources/NhetrinhReadback/Driver/IconMatch.swift `borderColour` (commit 2e05899: whole border)
source: _app/_Sources/NhetrinhReadback/Driver/IconMatch.swift `borderColour` (commit 4ee85bf: 4 corners)
source: _app/Tests/NhetrinhReadbackTests/_Dock/_IconMatchTests.swift `dockCaptureVerdict`, case `iconOnTileToTheEdge` (commit 4ee85bf)
source: _app/Tests/NhetrinhReadbackTests/_Dock/_IconMatchTests.swift `dockCornerReviewGaps`, 4 cases (commit 90b8cab)
links: fix=yes lesson=no evidence=no toolgap=none

## Mechanism

R2 took the Dock's colour from inside the captured item, so a tile could become "the Dock":
only the icon counted as occupied, it matched its own shape, and R2 passed while the tile was
there (NT-BUG-002 shape). Two instances:

| # | Rule (commit) | Tile read as the Dock |
|---|---|---|
| 1 | median of the whole border (2e05899) | a dark rounded tile as large as the item |
| 2 | median of the 4 corners (4ee85bf) | a square tile as large as the item; a light tile with light below the item |

Instance 2 also failed the other way: light pixels below the item made the bare icon fail.
Not proven: that the real Dock capture has the tile at its edge (R2 has never run: no permission).

## Confirm

`_app/scripts/test.sh` at commit 90b8cab: `dockCornerReviewGaps` records 4 issues
(`squareTileToTheEdge`, `paleTileOnLightDock`, `lightTileLightCornersBelow`, `bareIconLightCornersBelow`).
