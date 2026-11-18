# NT-TG-002 — Screen capture leaks other windows

id: NT-TG-002
family: UIX
status: OPEN
date: 2026-11-16
found_by: development (MVP B screenshot attempt)
source: MVP B screenshot attempt (2026-11-16): a region capture caught another app's window instead of nhetrinh
links: fix=no lesson=no evidence=no toolgap=NT-TG-002

## Gap

`screencapture -R` captures whatever is on screen in that region, including private windows of other apps.

## Workaround

Do not capture screen regions. Delete any capture that shows another app at once.
R2 (readback) still captures a region: the Dock item and a ring clamped to the Dock list's own
frame (`DockIcon.captureRect(around:dock:)`, test `ringNeverLeavesTheDock`), to a temporary file
deleted in the same step; `.gitignore` holds `hubs/failures/evidence/readback/*.png` as a guard.
Not proven: that the Dock's Accessibility frame holds only Dock pixels on the real screen.
Seen against it (NT-GAT-007, 19:40 capture): on a left Dock the frame's far 5 pt are a lighter,
uneven strip past the Dock's visible edge. What shows there is not proven (wallpaper or border).

## Wanted

Capture one window by id (`screencapture -l <windowid>`, id from `CGWindowListCopyWindowInfo` for our pid).
