# NT-GAT-012 — A test's sheet showed the browser window

id: NT-GAT-012
family: GAT
status: OBSERVED
date: 2026-11-17
signature: noTestWindowIsEverVisible
source: nhetrinh_wt/REVIEW_P8_SIDE.md, part (b): the tests that attached sheets or showed the Settings Hub
source: _app/Tests/NhetrinhTests/Page/_SheetGapsTests.swift (`NoWindowOnScreenTests`)
source: _app/_Sources/_Nhetrinh/Support/Screen.swift (P8-TESTWIN-1)
observed: the headmate saw a browser window with tab t1 selected on screen while unit tests ran
links: fix=no lesson=yes evidence=no toolgap=none

## Mechanism

No unit test calls `showWindow`. `_SheetGapsTests`, `FoldersTests`, `GroupMenuTests`, `_GroupsTests`
and `DownloadGuardTests` asked a question through `ask`, which began an AppKit sheet on the hidden
browser window; `ToolsProbeTests` called `showSettingsHub`, which ordered the hub front. The review
reads `aSheetNeverOutlivesOrHidesTheTabThatAsked` (File > Close Tab) as the window seen: t1 and t3
left, t1 selected. Not proven: that a sheet on a hidden window orders it on screen (AppKit's known
behaviour; not run here, to keep windows off the headmate's screen).

## Confirm

`NoWindowOnScreenTests.noTestWindowIsEverVisible` takes every path that showed a window and reads
`NSApp.windows.filter(\.isVisible)`. Red when the held presenter orders the hub in (alpha 0, off
screen, so nothing showed): `Expectation failed: visible.isEmpty`.

## Fix

Every sheet and the hub go through `Screen.presenter`. Before a launch it is `HeldScreen`: nothing is
ordered on screen; a held sheet is read as shown (`shownSheet`) and its buttons answer it with
AppKit's response. `AppDelegate` sets `AppKitScreen` first thing at launch. The named tests close
their browser window (`closeAfterTest`). Red when a held button answers nothing: `GroupMenuTests` 4
issues and the guard. Not proven: the app's AppKit path after the change (no readback in this task).
