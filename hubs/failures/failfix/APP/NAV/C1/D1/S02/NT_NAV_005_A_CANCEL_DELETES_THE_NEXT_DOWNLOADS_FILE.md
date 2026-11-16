# NT-NAV-005 — A cancel deletes the next download's file — fix

id: NT-NAV-005
family: NAV
status: OBSERVED
date: 2026-11-17
source: _app/_Sources/_Nhetrinh/_Browser/Page/Outside/_Downloads.swift on e7dccf9 (`end`, `remove(_:after:)`)
source: _app/Tests/NhetrinhTests/Page/Outside/_DownloadRaceTests.swift `aCancelNeverRemovesTheNextDownloadsFile`
links: fix=yes lesson=no evidence=no toolgap=none

## Fix that holds (P5-FIX-1, p5/review, not on master)

The partial file has its own name, `<name>.download` (NT-NAV-010), and a cancel keeps the name taken until WebKit's `cancel` completion: then the partial file goes, then the name is free. No delayed removal is left.

## Wrong fixes

A longer delay before the second removal: the race only moves.

## Proof

Green after P5-FIX-1 (test.sh); the second download is `race.txt` or `race (1).txt` and stays. Not read back.
