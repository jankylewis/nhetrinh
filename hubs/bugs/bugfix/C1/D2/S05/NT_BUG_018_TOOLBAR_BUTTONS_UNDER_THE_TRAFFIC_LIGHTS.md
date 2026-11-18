# NT-BUG-018 — Toolbar buttons under the traffic lights — fix

id: NT-BUG-018
family: UIX
status: OBSERVED
date: 2026-11-17
source: _app/_Sources/NhetrinhCore/Shell/_ToolbarLayout.swift (`leading(zoomMaxX:toolbarMinX:)`, P8-CHROME-1)
source: _app/_Sources/_Nhetrinh/UI/Bars/_Toolbar/ToolbarView+Lights.swift (`placeRow`)
links: fix=yes lesson=no evidence=no toolgap=none

## Change

The toolbar's row starts a gap right of the real zoom button whenever that button is over the toolbar,
read on every layout (`hubs/failures/failfix/APP/UIX/C1/D1/S02/NT_UIX_005_TOOLBAR_ROW_AT_A_FIXED_MARGIN.md`).
The new Toggle Sidebar button is the row's first button, so it clears them too (NT-FEAT-047).

## Proof

`_ToolbarLayoutTests` red on the stub, green with the fix; `theLeftButtonsClearTheTrafficLights` red under
a mutation of `placeRow` with the sidebar hidden (P8-CHROME-1, test.sh). R48 written, not read back.
Not on master. Not proven: full screen.
