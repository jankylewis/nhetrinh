# NT-UIX-005 — Toolbar row at a fixed margin

id: NT-UIX-005
family: UIX
status: OBSERVED
date: 2026-11-17
signature: theLeftButtonsClearTheTrafficLights
source: _app/_Sources/_Nhetrinh/UI/Bars/_ToolbarView.swift on e626a4d (`row.leadingAnchor ... constant: 8`)
source: _app/_Sources/_Nhetrinh/_Browser/_Window/_BrowserWindowController.swift on e626a4d (`.fullSizeContentView`, `titlebarAppearsTransparent`)
source: _app/Tests/NhetrinhTests/Tabs/PageChromeTests.swift `theLeftButtonsClearTheTrafficLights`
links: fix=yes lesson=no evidence=no toolgap=none

## Mechanism

The window draws its content under the title bar (`.fullSizeContentView`), so the close, minimize and zoom
buttons (the traffic lights) sit over the content's top left. With the sidebar shown they are over the
sidebar. Toggle Sidebar collapses it: the toolbar then starts at the window's left edge, and its row was
pinned 8 points from that edge whatever covered it. Back and forward were drawn under the traffic lights.

## Confirm

`ToolbarLayoutTests` on the stub that keeps the margin: `leading(zoomMaxX: 66, toolbarMinX: 0)` is 8,
wanted 74. Mutation of the fix (`placeRow` returns at once): `theLeftButtonsClearTheTrafficLights` red with
the sidebar hidden, green with it shown (P8-CHROME-1, test.sh). Not proven: full screen, where the
traffic lights live in the title bar's own window (no test shows a window).
