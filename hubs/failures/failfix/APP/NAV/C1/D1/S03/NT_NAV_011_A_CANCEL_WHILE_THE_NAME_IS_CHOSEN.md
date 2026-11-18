# NT-NAV-011 — A cancel while the name is chosen — fix

id: NT-NAV-011
family: NAV
status: OBSERVED
date: 2026-11-17
source: _app/_Sources/_Nhetrinh/_Browser/Page/Outside/_Downloads.swift (`decideDestinationUsing`)
links: fix=yes lesson=no evidence=no toolgap=none

## Fix that holds (P5-FIX-1, p5/review, not on master)

The continuation checks that the entry still runs; if not, it frees the name and gives WebKit no destination.

## Wrong fixes

none

## Proof

From the code only; no test reaches the window.
