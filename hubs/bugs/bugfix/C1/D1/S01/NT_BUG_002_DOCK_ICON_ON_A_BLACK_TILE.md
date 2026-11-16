# NT-BUG-002 — Dock icon on a black tile — fix

id: NT-BUG-002
family: UIX
status: FIXED
date: 2026-11-16
source: _app/_Sources/_Nhetrinh/AppDelegate.swift (`NSApp.applicationIconImage`)
source: _app/assets/_icon/tools/_pixelate.swift (pixel style, hard alpha, fills the canvas)
source: headmate Dock screenshot 2026-11-16 (the running app, after the change)
links: fix=yes lesson=yes evidence=yes toolgap=NT-TG-001

## Change

1. Ship `AppIcon.png` in `Contents/Resources` and set it as the Dock icon at launch.
2. Icon redrawn as 80x80 pixel art with hard alpha, scaled to fill the canvas (headmate asked for bigger + pixel style).

## Proof

The headmate confirmed on 2026-11-16, by a Dock screenshot, that the running app shows Hirono
with no tile. R2 passed on master 0f99aee (below). The headmate's two other apps use the same call (`setApplicationIconImage` found in
both binaries) and show no tile.

Not fixed: when the app is not running, macOS draws the bundle `.icns` on a tile (see the
bugfacing entry, "Known limit"); accepted by the headmate, not to be fixed
(`hubs/product/plan/DECISIONS.md` D20).

## Proof on master (0f99aee)

`hubs/failures/evidence/readback/_LATEST.md` (2026-11-16 21:24, PASS 8 of 8; app 0.1.0 built from fba7d9e, whose app sources equal master 0f99aee), R2: `silhouette agreement 98 %, icon at 92 % of the Dock item` (running app). The bundle `.icns` tile when not running stays the accepted limit (D20).
