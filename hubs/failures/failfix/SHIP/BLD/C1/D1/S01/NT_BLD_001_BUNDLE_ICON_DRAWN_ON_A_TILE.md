# NT-BLD-001 — Bundle icon drawn on a tile — fix

id: NT-BLD-001
family: BLD
status: FIXED
date: 2026-11-16
source: _app/_Sources/_Nhetrinh/AppDelegate.swift
links: fix=yes lesson=yes evidence=yes toolgap=NT-TG-001

## Fix that holds

Keep the `.icns` (Finder, Launchpad) and set `NSApp.applicationIconImage` from `AppIcon.png` at launch (Dock).

## Wrong fixes

1. A bigger or tighter-cropped `.icns`: still drawn on the tile.
2. Building against an older SDK: one of the headmate's apps is built with the same SDK as nhetrinh and has no tile; the runtime call is the difference.

## Proof

Not proven: Dock readback pending (NT-TG-001).

## Proof on master (0f99aee)

`hubs/failures/evidence/readback/_LATEST.md` (2026-11-16 21:24, PASS 8 of 8; app 0.1.0 built from fba7d9e, whose app sources equal master 0f99aee), R2: `silhouette agreement 98 %, icon at 92 % of the Dock item`.
