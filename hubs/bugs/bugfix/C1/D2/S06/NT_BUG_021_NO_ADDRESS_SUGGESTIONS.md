# NT-BUG-021 — The address bar shows no visited pages — fix

id: NT-BUG-021
family: NAV
status: OBSERVED
date: 2026-11-18
source: _app/_Sources/NhetrinhCore/_Navigation/_Address/History/_HistoryStore.swift
source: _app/_Sources/_Nhetrinh/_Browser/_Window/Chrome/AddressBar.swift
source: _app/_Sources/_Nhetrinh/UI/Bars/_Toolbar/SuggestionList.swift
links: fix=yes lesson=no evidence=no toolgap=none

## Change

Record finished web pages in a capped local SQLite store. While the user types, show matching history and open
pages beneath the address field. Arrow keys choose a row; Return or click opens it; Escape closes the dropdown.
Settings Hub can stop recording, and Clear All empties the store.

## Proof

Core, app wiring and readback-step tests passed with `_app/scripts/test.sh`. Ranking, matching and the off switch
were each mutated and each focused test failed. R54 was written and unit tested but not run; the installed app is
in use by the headmate. No commit or readback verdict yet; live behavior and the lightness budget are not proven.
