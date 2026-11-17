# NT-GAT-014 — R43 pinned a stale session version — fix

id: NT-GAT-014
family: GAT
status: OBSERVED
date: 2026-11-17
source: _app/_Sources/NhetrinhReadback/_Steps/Tabs/Sidebar/Groups/VersionOneStep.swift (`isCurrentSave`, P8-R43-FIX)
source: _app/_Sources/NhetrinhCore/Tabs/Lifecycle/Tree/Session/_TreeSession.swift (`TreeSessionStore.version(of:)` made public)
source: _app/Tests/NhetrinhReadbackTests/Steps/Tabs/Sidebar/VersionOneStepTests.swift
links: fix=yes lesson=no evidence=yes toolgap=none

## Fix that holds

R43 asks `VersionOneStep.isCurrentSave`: the save's `version` (read by the app's own
`TreeSessionStore.version(of:)`) equals `TreeSession.version`, the one constant the app writes,
and the decoded tabs are the 3 the step wrote. The failure text and the PASS line name the
version from the same constant. The unit test builds the save with the app's
`TreeSessionStore.encode`: a step that pins any number the app does not write fails it. It also
refuses a version 2 save, the version 1 file, a newer version, other tabs and no file.

## Wrong fixes

- Changing the literal to `"version":3`: the next schema change fails R43 the same way.

## Proof

`r43AcceptsOnlyTheVersionTheAppWrites` red against the old check (2 issues), green with the fix
(test.sh). Not proven: R43 PASS on the installed app (not read back; no app run in P8-R43-FIX).
