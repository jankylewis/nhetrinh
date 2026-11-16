# NT-BUG-007 — A call in a background tab is unloaded — fix

id: NT-BUG-007
family: TAB
status: OBSERVED
date: 2026-11-17
source: _app/Tests/_NhetrinhCoreTests/Tabs/Lifecycle/PressurePolicyTests.swift `aCapturingTabIsKept` (P4P6-FIX-1)
links: fix=yes lesson=no evidence=no toolgap=none

## Change

`UnloadPolicy.TabState.isCapturing`; the app sets it from `cameraCaptureState` / `microphoneCaptureState` (not `.none`: on or muted); `tabsToUnload` keeps such a tab at every level.

## Proof

`aCapturingTabIsKept` red on the stub (3 issues: normal, warning, critical), green with the fix. The app wiring is not unit tested (WebKit capture cannot be faked); not read back.
