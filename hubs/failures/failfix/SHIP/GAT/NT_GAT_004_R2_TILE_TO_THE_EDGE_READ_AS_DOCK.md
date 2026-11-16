# NT-GAT-004 — R2 takes a tile to the edge for the Dock — fix

id: NT-GAT-004
family: GAT
status: OBSERVED
date: 2026-11-16
source: _app/_Sources/NhetrinhReadback/Driver/IconMatch.swift (`borderColour` reads the 4 corners)
source: _app/Tests/NhetrinhReadbackTests/_IconMatchTests.swift (6 captures x a light and a dark Dock)
links: fix=yes lesson=no evidence=no toolgap=none

## Fix that holds

The Dock's colour is the median of 3 x 3 pixels at each of the 4 corners: a rounded tile never
covers the very corners. Tests: bare icon (pass); small icon on an inset tile; icon on a tile to
the edge; icon on a tile at 96 %; a bare icon at 40 %; blank. Each on a light (0.85) and a dark (0.25) Dock.

## The wrong fix

Raise the agreement threshold: the tile-to-edge capture scored 0.96, as high as a bare icon can.

## Proof

Red first: tile to the edge passed R2 on both Docks (2 issues). Green after the fix, 12 of 12.
Not proven: R2 on the real Dock. A real icon that reaches the capture's corners would make the
corners icon-coloured; nhetrinh's icon is clear there (`_DockIcon.png`: alpha 0 in each corner
patch of 4/128 of the side, read 2026-11-16).
