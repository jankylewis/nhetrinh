# NT-GAT-007 — R2 scored past the icon on a side Dock

id: NT-GAT-007
family: GAT
status: FIXED
date: 2026-11-16
found_by: readback (R2 FAIL, readback 19:40)
signature: R2 FAIL: the Dock item does not show the bare icon: silhouette agreement 76 %, icon at 84 % of the Dock item
source: _app/_Sources/NhetrinhReadback/Driver/IconMatch.swift `measure`, `ringColour` (commit 5f2592e: the whole item scored, one ring colour)
source: _app/_Sources/NhetrinhReadback/Driver/DockIcon.swift `capture` (commit 5f2592e: the item clamped to the capture)
source: R2 capture and numbers of the 19:40 run, kept by `--keep-capture` in a folder outside the repository (never copied in: it shows other apps' icons)
observed: Dock on the left, frame 34 x 770 pt; item 34 x 22 pt from x 13.6, past the Dock frame's far side (x 44); capture 34 x 33 pt (68 x 66 px)
observed: the matemaster and the headmate see no tile behind the icon in the capture
links: fix=yes lesson=no evidence=yes toolgap=NT-TG-002

## Mechanism

R2 scored a 48 x 48 grid over the whole item and compared each cell to one colour, the median of
the ring around the item. On a side Dock the item is wider across the Dock (34 pt) than the icon
(a square as long as the item along the Dock, 22 pt). So the grid took in the far 5 pt of the
Dock frame, a lighter, uneven strip (about 100 105 120 against the Dock's 73 76 85) past the
Dock's visible edge. Those cells read as occupied where the icon is transparent. And the square
icon was matched stretched over a 34 x 22 item. Measured with the 5f2592e `IconMatch` on the
kept capture: 0.762 (as R2); 0.866 on the item without the strip; occupancy shows the strip as
9 occupied columns of 48.

Not the neighbours or the running dot: the neighbours' tiles lie in the ring before and after
the item (rows 0-3 and 61-66 px) and leave the ring median at the Dock's colour (73 76 85). The
dot is in the ring across the Dock, outside the item. The matemaster's first reading named
them; the measurement above does not support it.

Not proven: what the strip shows (wallpaper through the Dock's edge, or the Dock's own border).

## Confirm

Run the 5f2592e `IconMatch.measure` on the kept capture with the item in pixels
(x 7.2 y 10 w 60.8 h 44): 0.762, 0.84. The fixtures `bareLeft` and `bareBottom` in
`_Dock/DockAxisTests.swift` fail with that version of `measure` (red run of P0-FIX-4).
