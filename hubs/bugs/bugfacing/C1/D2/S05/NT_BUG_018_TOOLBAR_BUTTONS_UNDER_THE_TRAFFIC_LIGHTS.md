# NT-BUG-018 — Toolbar buttons under the traffic lights

id: NT-BUG-018
family: UIX
status: OBSERVED
date: 2026-11-17
found_by: headmate (2026-11-17, P8-CHROME-1 brief)
signature: theLeftButtonsClearTheTrafficLights
source: _app/_Sources/_Nhetrinh/UI/Bars/_ToolbarView.swift on e626a4d (`row.leadingAnchor ... constant: 8`)
source: _app/Tests/NhetrinhTests/Tabs/PageChromeTests.swift `theLeftButtonsClearTheTrafficLights`
observed: reported by the headmate on the installed app (P8-CHROME-1 brief); no screen capture kept
links: fix=yes lesson=no evidence=no toolgap=none
cause: NT-UIX-005

## Steps

Hide the sidebar with View > Toggle Sidebar (⌘S).

Expected: the toolbar's buttons start right of the window's close, minimize and zoom buttons.
Actual (e626a4d, headmate): back and forward sit under those buttons at the top left; they overlap.

## Cause

The toolbar's row was pinned 8 points from its own left edge; with the sidebar hidden that edge is the
window's, under the traffic lights (NT-UIX-005).
