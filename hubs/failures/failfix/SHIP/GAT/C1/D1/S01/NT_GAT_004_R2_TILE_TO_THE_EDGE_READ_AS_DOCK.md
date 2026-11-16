# NT-GAT-004 — R2 takes a tile to the edge for the Dock — fix

id: NT-GAT-004
family: GAT
status: FIXED
date: 2026-11-16
source: _app/_Sources/NhetrinhReadback/Driver/DockIcon.swift (`ringPoints`, `captureRect(around:dock:)`, `capture`)
source: _app/_Sources/NhetrinhReadback/Driver/IconMatch.swift (`measure(capture:icon:item:)`, `ringColour`)
source: _app/Tests/NhetrinhReadbackTests/_Dock/_IconMatchTests.swift `dockCaptureVerdict` (6 captures x 2 Docks)
source: _app/Tests/NhetrinhReadbackTests/_Dock/DockRingTests.swift `dockCornerReviewGaps`, `ringNeverLeavesTheDock`, `ringIsSmallerAtTheDocksEdge`, `noRingIsNeverAPass`
links: fix=yes lesson=no evidence=no toolgap=none

## Fix that holds

R2 captures the item grown by 6 pt on each side, clamped to the frame of the Dock list that holds
it: no pixel outside the Dock (NT-TG-002); at the Dock's edge the ring is smaller. The picture is
a temporary file, read and deleted in the same step; the report keeps only numbers. The Dock's colour is
the median of that ring, outside the item, where no tile of the item can reach. The grid is
read inside the item only. No ring is never a pass. Cases: the 6 captures of
`dockCaptureVerdict` on a 0.85 and a 0.25 Dock; a square tile to the edge; light below the item
with a light tile and with the bare icon; the item at the Dock's bottom edge (no ring below)
with a square tile and with the bare icon.

## Known limit

`paleTileOnLightDock` (a 0.80 tile on a 0.85 Dock) still passes R2: the tile is 22 from the Dock
colour, under `colourDistance` (30). The case is kept under `withKnownIssue`, so the test says so
when it starts to fail correctly. A smaller distance tells it apart in the drawn captures. No real
Dock capture exists to show that the Dock's blurred material stays within a smaller distance, so the
distance is not lowered.

## The wrong fixes

Raise the agreement threshold: the tile-to-edge capture scored 0.96, as high as a bare icon can.
Read the item's corners (commit 4ee85bf): a square tile covers them (instance 2).

## Proof

Red first: commit 90b8cab, `_app/scripts/test.sh`, 4 issues in `dockCornerReviewGaps`. Green after,
`paleTileOnLightDock` as the one known issue. Mutation: the ring read from inside the item instead
fails `squareTileToTheEdge`, `squareTileAtDockEdge`, `lightTileLightCornersBelow`, both
`iconOnTileToTheEdge` cases and `noRingIsNeverAPass`.
Not proven: R2 on the real Dock; that the ring holds only Dock colour (neighbour items, the
running dot); that the Dock list's Accessibility frame holds only Dock pixels.

## Review P0-REV-2: half-point Dock frame

`DockIcon.capture` rounded x, y, width and height one by one for `screencapture -R`, so a Dock
frame on a half point grew up to 1 pt past the Dock's edge. `DockIcon.captureRect` now rounds
inward to whole points, inside the Dock frame; `capture` only converts it.
Red first: commit 7181133, 2 issues in `ringIsWholePointsInsideTheDock`. Green after.
Not proven: that the Dock's Accessibility frames are ever fractional on a real display.

## Proof on master (0f99aee)

Red-first tests green in CI run 43885459211 (PR #1, head 402adec, the same tree as master 0f99aee); `hubs/failures/evidence/readback/_LATEST.md` (2026-11-16 21:24, PASS 8 of 8; app 0.1.0 built from fba7d9e, whose app sources equal master 0f99aee), R2 on the real Dock: `silhouette agreement 98 %`. The pale tile on a light Dock stays a known limit.
