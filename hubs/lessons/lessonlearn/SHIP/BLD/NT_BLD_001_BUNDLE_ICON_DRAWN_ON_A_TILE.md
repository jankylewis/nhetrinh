# NT-BLD-001 — Bundle icon drawn on a tile — lesson

id: NT-BLD-001
family: BLD
status: OBSERVED
date: 2026-11-16
links: fix=yes lesson=yes evidence=yes toolgap=NT-TG-001

## Believed

A transparent `.icns` gives a Dock icon with no background, so the tile came from the image (padding, soft edges) or the SDK.

## What changed it

Rendering four apps' icons showed the tile on all of them, and the headmate's tile-free apps both call `setApplicationIconImage`.

## Rule

When our app looks different from a reference app, check what the reference binary calls before changing our assets.
