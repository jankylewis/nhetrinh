# NT-NAV-012 — Two spellings of one name — fix

id: NT-NAV-012
family: NAV
status: OBSERVED
date: 2026-11-17
source: _app/_Sources/_Nhetrinh/_Browser/Page/Outside/_Downloads.swift (`reserve`)
source: _app/_Sources/NhetrinhCore/_Navigation/Downloads/_DownloadNamer.swift (`key`)
links: fix=yes lesson=no evidence=no toolgap=none

## Fix that holds (P5-FIX-1, p5/review, not on master)

`reserved` holds `DownloadNamer.key(name)`: canonical composition, lower case.

## Wrong fixes

none

## Proof

`sameFileIgnoresCaseAndNormalization` red on a stub, green after (test.sh).
