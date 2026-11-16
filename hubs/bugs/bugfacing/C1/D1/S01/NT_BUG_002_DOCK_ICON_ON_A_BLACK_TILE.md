# NT-BUG-002 — Dock icon on a black tile

id: NT-BUG-002
family: UIX
status: OBSERVED
date: 2026-11-16
signature: Dock icon on a black tile
source: headmate report 2026-11-16 ("bigger plz, and no black background", Dock screenshot)
observed: the transparent Hirono icon showed small, inside a dark rounded tile, in the Dock
links: fix=yes lesson=yes evidence=yes toolgap=NT-TG-001
cause: NT-BLD-001

## Steps

Build the app with a transparent `AppIcon.icns`, launch it, look at the Dock.

Expected: the character alone, full size, no background (like the headmate's other apps).
Actual: the character, scaled down, on a black rounded tile.

Status OBSERVED: the runtime-icon fix is in the code; no Dock readback yet (NT-TG-001).
