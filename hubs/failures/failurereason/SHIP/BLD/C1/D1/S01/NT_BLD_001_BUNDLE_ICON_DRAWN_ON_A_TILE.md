# NT-BLD-001 — Bundle icon drawn on a tile

id: NT-BLD-001
family: BLD
status: FIXED
date: 2026-11-16
found_by: headmate (2026-11-16 Dock report, NT-BUG-002)
signature: icon on a tile
source: headmate report 2026-11-16 (Dock screenshot, NT-BUG-002)
source: `NSWorkspace.icon(forFile:)` render of four apps (rnd check, 2026-11-16)
observed: every `.icns` app icon rendered on a rounded tile, including the headmate's two other apps (one black tile, one white tile)
links: fix=yes lesson=yes evidence=yes toolgap=NT-TG-001

## Mechanism

This macOS draws a bundle icon (`CFBundleIconFile`) on a rounded tile when the image is not a full tile itself.
Transparency in the `.icns` does not prevent it. An image set at runtime with `NSApp.applicationIconImage` is drawn as-is.

## Confirm

`strings <binary> | grep setApplicationIconImage` on an app that shows no tile.
