# NT-GAT-014 — R43 pinned a stale session version

id: NT-GAT-014
family: GAT
status: OBSERVED
date: 2026-11-17
found_by: readback (R43 FAIL, full readback 2026-11-17 13:19)
signature: R43 FAIL the save at quit is not version 2
source: hubs/failures/evidence/readback/_LATEST.md (full run 13:19, build c751b08: R43 FAIL)
source: _app/_Sources/NhetrinhReadback/_Steps/Tabs/Sidebar/Groups/VersionOneStep.swift:33 at c751b08 (`text.contains("\"version\":2")`)
source: _app/_Sources/NhetrinhCore/Tabs/Lifecycle/Tree/Session/_TreeSession.swift:10 (`TreeSession.version = 3`, commit a6cdec3)
source: _app/_Sources/NhetrinhCore/Tabs/Lifecycle/Tree/Session/_TreeSession.swift:67-73 (`encode` writes `TreeSession.version`)
links: fix=yes lesson=no evidence=yes toolgap=none

## Mechanism

P8-GROUPS-1 (a6cdec3) made the session file version 3: `TreeSessionStore.save` writes
`TreeSession.version`, now 3. The same commit moved `VersionOneStep.swift` into `Groups/` without
a change (`git show a6cdec3 --stat`: 0 lines). R43 checked the saved bytes for the literal
`"version":2`, so the app's correct version 3 save failed it. Nothing tied the step's number to
the app's: no unit test covered R43's check.

The app is not at fault: R43's other checks passed before this one (the 3 rows, row 2 selected,
`session.v1.json` holds the version 1 bytes), and the decode of the save is the same function the
app uses.

## Confirm

By reading the step and the app's save (no app run, P8-R43-FIX). Red first:
`r43AcceptsOnlyTheVersionTheAppWrites` (Tests/NhetrinhReadbackTests/Steps/Tabs/Sidebar/
VersionOneStepTests.swift) against the literal check: the app's own save refused, a version 2
save accepted (test.sh, 2 issues).

## Fix

See failfix NT-GAT-014.
