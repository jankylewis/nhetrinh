# NT-GAT-007 — R2 scored past the icon on a side Dock — fix

id: NT-GAT-007
family: GAT
status: OBSERVED
date: 2026-11-16
source: _app/_Sources/NhetrinhReadback/Driver/IconMatch.swift (`DockAxis`, `scoredSquare`, `lineColours`, `measure(...axis:)`)
source: _app/_Sources/NhetrinhReadback/Driver/DockIcon.swift `capture` (the item no longer clamped)
source: _app/_Sources/NhetrinhReadback/_Steps/SystemSteps.swift `dockIconHasNoTile` (`DockAxis.of(item.dock)`)
source: _app/Tests/NhetrinhReadbackTests/Steps/DockAxisTests.swift `r2JudgesTheIconNotItsNeighbours` (4 cases), `dockAxisFollowsTheDocksLongSide`, `scoredSquareIsTheItemsLengthCentred`
links: fix=yes lesson=no evidence=yes toolgap=NT-TG-002

## Fix that holds

The Dock's long axis comes from its frame (taller than wide: a side Dock). R2 scores only a
square as long as the item along the Dock, centred on the whole item (not clamped to the
capture); cells off the capture are not scored, and under half the square scored is 0. The
background is read per line across the Dock: the median of the ring before and after the item
along the Dock on that line. So the strip past the Dock's edge is background on its own lines,
the running dot (across the Dock) is never read, a neighbour's tile takes under half a line, and
a tile around our icon is still far from the Dock colour (NT-GAT-004 holds: the ring is outside
the item). Fixtures, 2x, the 19:40 geometry on a left and a bottom Dock: neighbour tiles before
and after, the dot on the screen side, a lighter uneven strip on the far side; bare icon passes,
icon on a dark tile fails. The old cases run as a bottom Dock.

## The wrong fixes

Lower the 90 % bar: a tile near the edge passes too. Read the background from the strips across
the Dock: the dot and the strip are there. Clamp the square to the capture: the icon's centre
moves 3.4 px off, at the edge of the offset search.

## Proof

Red first: `r2JudgesTheIconNotItsNeighbours` with the 5f2592e `measure` (clamped item, no axis):
`bareLeft` and `bareBottom` fail. Green after, all old cases green (`paleTileOnLightDock` stays
the known NT-GAT-004 limit). Mutations: the whole item scored, or the lines read across the
Dock, fail `bareLeft` and `bareBottom` again. On the kept 19:40 capture (scratch probe, outside
the repository): 0.974, scale 0.92, PASS; with a dark tile painted behind the real icon on the
same capture: 0.530 and 0.654, FAIL.
Headmate ruling (NT-TG-002 stands): no pixel outside the Dock frame. `narrowLeftDockCaptureStaysInTheFrame`
(4 items on the 19:40 left Dock) and `cutSquareIsScoredInsideTheCapture` (square cut 7 of 44 px:
bare passes, tile fails) are green. The 5 pt strip is inside the Dock's Accessibility frame.
Not proven: R2 on the installed app. Not rebuilt or read back yet (one batched rebuild).
