# NT-GAT-008 — the window read was not a window

id: NT-GAT-008
family: GAT
status: OPEN
date: 2026-11-16
found_by: readback (R1, R3-R7 NOT READ BACK, readback 20:07)
signature: window "nhetrinh", 2 children, first roles [AXApplication, AXMenuBar], read error 0
source: `hubs/failures/evidence/readback/_LATEST.md` (20:07, commit 663acba): R1, R3-R7 NOT READ BACK with the signature
source: `_app/_Sources/NhetrinhReadback/Driver/AppSession.swift` `window()` (commit 3d35e8d: `app.windows.first`, any role)
source: `git diff 5f2592e d76fce8 -- _app/_Sources/NhetrinhReadback`: `DockIcon.swift`, `IconMatch.swift`, `System/_SystemSteps.swift` only
links: fix=yes lesson=no evidence=yes toolgap=NT-TG-003

## Mechanism

`window()` took the first element of the application's `AXWindows` and never read its role. At
20:07 that element had the title "nhetrinh" and the children [AXApplication, AXMenuBar]: not the
app's window, which holds the sidebar and the address bar. Every step then searched a tree with no
`nhetrinh.*` identifier.

Not the readback's source. The readback that passed R1-R7 at 19:40 was built at 19:34 from
5f2592e (the matemaster's correction); every failing one (19:51, 19:59, 20:01, 20:07) from d76fce8
or later. The source diff between them is R2's pixel math only (`DockAxis`, `scoredSquare`,
`lineColours`, the item no longer clamped): no attribute read, cast, pid or window lookup changed.
At 20:07 the Dock's tree read empty too (R2: 0 Dock items), so two apps' trees went wrong at once.
That points to the readback process's Accessibility access (NT-TG-003: a signed rebuild of the
readback app at 19:51), not to the steps. Not proven: what macOS changed, and what element
`AXWindows` gave.

## Confirm

The next run: R1 says `the app's windows read as [<roles>], none has the role AXWindow` when the
read is wrong in the same way; with the role of a real window it reads the tree as at 19:40.
