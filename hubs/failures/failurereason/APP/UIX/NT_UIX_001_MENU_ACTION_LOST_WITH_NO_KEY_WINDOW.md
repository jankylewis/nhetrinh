# NT-UIX-001 — Menu action lost with no key window

id: NT-UIX-001
family: UIX
status: OBSERVED
date: 2026-11-16
signature: after New Tab the sidebar has 1 rows, not 2
source: readback 2026-11-16 18:57, app 0.1.0 from commit 0d00e08 (`hubs/failures/evidence/readback/_LATEST.md` on branch `p0/harness-docs`)
source: _app/_Sources/_Nhetrinh/UI/AppMenu.swift at commit 0d00e08 (browser items made with no target)
source: _app/Tests/NhetrinhTests/_AppMenuTests.swift `browserItemReachesTheBrowserWithNoKeyWindow` (red, P0-FIX-1)
links: fix=yes lesson=no evidence=yes toolgap=none

## Mechanism

A menu item with a nil target sends its action to the first responder that implements it:
the key window's chain, then the main window's, then `NSApp` and its delegate. The browser
actions (`newTab:`, `closeTab:`, ...) live only on `BrowserWindowController`, which is in the
window's chain. The readback launches the app without activating it (`activates = false`,
`hubs/product/plan/DECISIONS.md` D18), so the app has no key window and no main window:
the action finds nobody and is lost. Address bar steps (R3, R4) pass because the text field
calls its own target, not the menu.

## Confirm

`_app/scripts/test.sh --filter NhetrinhTests` at P0-FIX-1 with the old `AppMenu`: the test process
is not active, `NSApp.keyWindow == nil` holds, and `NSApp.target(forAction:to:from:)` returns
`nil` for all 9 browser items checked (New Tab, Close Tab, Open Location, Toggle Sidebar,
Reload, Back, Forward, Tab 1, Tab 9): 9 issues, "File > New Tab reaches nil".

Not proven: that the installed app had no key window during the 18:57 run (not read from the
app; inferred from `activates = false`). Not proven: whether AppKit showed the items disabled.
