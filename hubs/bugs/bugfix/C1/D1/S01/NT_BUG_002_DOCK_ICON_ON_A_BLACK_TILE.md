# NT-BUG-002 — Dock icon on a black tile — fix

id: NT-BUG-002
family: UIX
status: OBSERVED
date: 2026-11-16
source: _app/_Sources/_Nhetrinh/AppDelegate.swift (`NSApp.applicationIconImage`)
source: _app/assets/_icon/tools/_pixelate.swift (pixel style, hard alpha, fills the canvas)
links: fix=yes lesson=yes evidence=yes toolgap=NT-TG-001

## Change

1. Ship `AppIcon.png` in `Contents/Resources` and set it as the Dock icon at launch.
2. Icon redrawn as 80x80 pixel art with hard alpha, scaled to fill the canvas (headmate asked for bigger + pixel style).

## Proof

Not proven: no Dock readback after the change. The headmate's two other apps use the same call (`setApplicationIconImage` found in both binaries) and show no tile.
