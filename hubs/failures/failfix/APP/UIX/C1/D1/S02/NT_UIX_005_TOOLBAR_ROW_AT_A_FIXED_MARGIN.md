# NT-UIX-005 — Toolbar row at a fixed margin — fix

id: NT-UIX-005
family: UIX
status: OBSERVED
date: 2026-11-17
source: _app/_Sources/NhetrinhCore/Shell/_ToolbarLayout.swift (`leading(zoomMaxX:toolbarMinX:)`, P8-CHROME-1)
source: _app/_Sources/_Nhetrinh/UI/Bars/ToolbarView+Lights.swift (`placeRow`, `zoomOnScreen`, `watchFullScreen`)
links: fix=yes lesson=no evidence=no toolgap=none

## Fix that holds

On every layout of the toolbar, `placeRow` reads the real zoom button
(`standardWindowButton(.zoomButton)`) and the toolbar on the screen, and sets the row's left edge to
`max(8, zoomMaxX + 8 - toolbarMinX)`, rounded up. A sidebar shown, hidden or sliding, a resize and full
screen (its end is also observed) all lay the toolbar out, so the row follows them.

## Wrong fix

A fixed left inset of about 70 points when the sidebar is hidden: the traffic lights move with the
title bar style and the system, and the inset would also show with the sidebar shown or sliding.

## Proof

Red first on the stub (P8-CHROME-1), green with the fix, red again under a mutation of `placeRow`
(test.sh). Not read back: R48 is written, not run. Not on master.
