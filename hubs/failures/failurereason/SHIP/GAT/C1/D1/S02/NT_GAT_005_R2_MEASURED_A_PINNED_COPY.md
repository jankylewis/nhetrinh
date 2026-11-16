# NT-GAT-005 — R2 measured a pinned copy of the app

id: NT-GAT-005
family: GAT
status: FIXED
date: 2026-11-16
signature: R2 FAIL: the Dock item does not show the bare icon: silhouette agreement 90 %, icon at 82 % of the Dock item
source: _app/_Sources/NhetrinhReadback/_Steps/System/_SystemSteps.swift `dockIconHasNoTile` (commit 0d00e08: `items.last`)
source: _app/_Sources/NhetrinhReadback/Driver/DockIcon.swift `items(title:)` (commit 0d00e08: filter by title only)
source: hubs/failures/evidence/readback/_LATEST.md (run P0-RUN-1, 2026-11-16 18:57, app commit 0d00e08)
observed: `defaults read com.apple.dock persistent-apps` lists two items titled nhetrinh: the installed app, then a copy in an agent's temporary folder; the copy was not running
observed: the headmate saw no tile on the running app's Dock item in the same session
links: fix=yes lesson=no evidence=yes toolgap=none

## Mechanism

R2 read every Dock item whose title is `nhetrinh` and measured the last one. A title names no
bundle: a pinned copy of the app (another build, another folder) has the same title. A copy that
is not running shows its bundle icon, which macOS draws on a tile (NT-BLD-001); only the running
app sets the bare icon at runtime. With the copy pinned after the installed app, `items.last` is
the copy, and R2 fails on an item that is not the app it launched. With the copy first, R2 would
have judged the right item by chance.

Not proven: that the P0-RUN-1 FAIL measured the copy. No Accessibility frame was read (an agent
session has no Accessibility grant, NT-TG-003); the order of the Dock's Accessibility children is
taken to follow the pinned list.

## Confirm

1. `defaults read com.apple.dock persistent-apps | grep file-label`: more than one `nhetrinh`?
2. `_app/scripts/test.sh` with `DockIcon.launchedItem` reduced to the last item: 5 of 6 cases of
   `r2MeasuresOnlyTheLaunchedApp` fail.
