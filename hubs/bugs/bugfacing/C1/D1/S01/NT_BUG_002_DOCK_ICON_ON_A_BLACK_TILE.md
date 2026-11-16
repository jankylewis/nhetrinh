# NT-BUG-002 — Dock icon on a black tile

id: NT-BUG-002
family: UIX
status: OBSERVED
date: 2026-11-16
signature: Dock icon on a black tile
source: headmate report 2026-11-16 ("bigger plz, and no black background", Dock screenshot)
observed: the transparent Hirono icon showed small, inside a dark rounded tile, in the Dock
observed: 2026-11-16, headmate Dock screenshot after the fix: the running app shows Hirono with no tile
links: fix=yes lesson=yes evidence=yes toolgap=NT-TG-001
cause: NT-BLD-001

## Steps

Build the app with a transparent `AppIcon.icns`, launch it, look at the Dock.

Expected: the character alone, full size, no background (like the headmate's other apps).
Actual: the character, scaled down, on a black rounded tile.

Status OBSERVED: the runtime-icon fix is in the code, and the headmate confirmed it by a Dock
screenshot on 2026-11-16. It stays OBSERVED until readback R2 passes (NT-TG-001).

## Known limit

When the app is not running (a pinned Dock item, Finder, Launchpad), macOS draws the bundle
`.icns` on a tile (NT-BLD-001); the runtime icon applies only while the app runs. R2 checks the
running app only. An Icon Composer icon is a candidate fix (not proven). Icon Composer needs
Xcode 26; the build uses Command Line Tools only. Headmate ruling pending.
