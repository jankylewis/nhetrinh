# NT-GAT-015 — R2 failed on build c751b08 — fix

id: NT-GAT-015
family: GAT
status: OBSERVED
date: 2026-11-17
source: _app/_Sources/NhetrinhReadback/Driver/DockIcon.swift `captureRect(of:dock:)` (no ring), `geometry`
source: _app/_Sources/NhetrinhReadback/Driver/IconMatch.swift `ItemPixels` (`dockColour`, `onDock`, `occupiedCells`), `edgeDepth`
source: _app/_Sources/NhetrinhReadback/_Steps/System/_SystemSteps.swift `dockIconHasNoTile` (the FAIL line)
source: _app/Tests/NhetrinhReadbackTests/_Dock/_IconMatchTests.swift `r2JudgesThe1357ItemOnItsOwnFrame` (3 cases)
source: _app/Tests/NhetrinhReadbackTests/_Dock/DockAxisTests.swift `r2JudgesTheIconNotItsNeighbours` (6 cases), `captureIsTheItemInsideTheDock`
source: _app/Tests/NhetrinhReadbackTests/_Dock/KeepCaptureTests.swift `failLineNamesTheItemAndTheCapture`
links: fix=yes lesson=no evidence=yes toolgap=NT-TG-001

## Fix that holds

R2 captures only the item's own Accessibility frame, clamped to the Dock: no ring, so no neighbour
and (on the 13:57 Dock) no running dot. The icon square stays as NT-GAT-007 put it. The Dock's
colour is read inside the item, beside the square across the Dock: the colour most of those
pixels share (median of the pixels within the colour distance of it), so the dot and the strip
past the Dock's edge are outvoted. Never the square's border, where a tile is (NT-GAT-004 holds).
Lines along the Dock at the item's ends that are off the Dock on 90 % of their length are past
its edge and not scored, up to a quarter of the square (`edgeDepth`); deeper, they are scored, so
a tile reaching the edge still counts. No Dock beside the square is never a pass. The bar stays
0.90 and 0.60. A FAIL line now ends with the item frame (pt) and the capture size (px).

## The wrong fixes

Lower the 90 % bar (NT-GAT-007). Read the Dock's colour from the square's border or corners: a
tile to the edge reads as Dock and passes (NT-GAT-004). Exclude any run of off-Dock lines from the
far end however deep: a tile next to the edge would be taken out with it.

## Proof

Red first, the old `measure` and the 6 pt ring: `r2JudgesTheIconNotItsNeighbours` `bareLeft`,
`bareBottom`, `bareRight` fail (neighbours touching the item); the 13:57 crop scores 0 (no ring).
Green after: 13:57 crop 0.970, scale 0.94, PASS; the same crop with a dark or a pale tile painted
behind the icon 0.521, FAIL; drawn tiles 0.447-0.532, FAIL; drawn bare icons 0.986-0.987.
`paleTileOnLightDock` stays the known NT-GAT-004 limit. Mutation `edgeDepth = 0`: the 13:57 crop
and the three drawn bare cases fail again. `_app/scripts/test.sh` green, checker 0 violations.
Not proven: R2 on the installed app (no readback run; the app was not started).
