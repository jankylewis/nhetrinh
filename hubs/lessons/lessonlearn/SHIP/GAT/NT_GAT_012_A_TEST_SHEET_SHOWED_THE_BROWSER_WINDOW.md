# NT-GAT-012 — A test's sheet showed the browser window — lesson

id: NT-GAT-012
family: GAT
status: OBSERVED
date: 2026-11-17
links: fix=no lesson=yes evidence=no toolgap=none

## Believed

A unit test that never calls `showWindow` shows nothing: its browser window stays hidden.

## What changed it

The headmate saw a browser window during the unit tests (`nhetrinh_wt/REVIEW_P8_SIDE.md`, part b).
A sheet begun on the window and the Settings Hub's `makeKeyAndOrderFront` reach the screen without a
`showWindow`.

## Rule

Nothing in the app orders a window or sheet in directly: it goes through `Screen.presenter`, which
holds it off screen until `AppDelegate` launches the app. A test reads a sheet through `shownSheet`,
closes its browser window at the end (`closeAfterTest`), and `noTestWindowIsEverVisible` keeps it so.
