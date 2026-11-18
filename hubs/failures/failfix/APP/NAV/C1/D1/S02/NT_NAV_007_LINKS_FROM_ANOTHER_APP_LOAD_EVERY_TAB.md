# NT-NAV-007 — Links from another app load every tab — fix

id: NT-NAV-007
family: NAV
status: OBSERVED
date: 2026-11-17
source: _app/_Sources/_Nhetrinh/_Browser/Page/Outside/BrowserWindowController+Outside.swift on e7dccf9 (`openIncoming`)
source: _app/Tests/NhetrinhTests/Page/Outside/IncomingTests.swift
links: fix=yes lesson=no evidence=no toolgap=none

## Fix that holds (P5-FIX-1, p5/review, not on master)

Every link is added as a tab, unloaded; only the last is selected, so only it loads.

## Wrong fixes

none

## Proof

`linksFromAnotherAppLoadOnlyTheShownTab` green (test.sh). Not read back. Merge note: p7 inserts through the tree (NT-TAB-003).
