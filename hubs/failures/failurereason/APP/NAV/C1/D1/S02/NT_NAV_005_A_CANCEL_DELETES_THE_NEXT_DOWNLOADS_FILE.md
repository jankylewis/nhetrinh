# NT-NAV-005 — A cancel deletes the next download's file

id: NT-NAV-005
family: NAV
status: OBSERVED
date: 2026-11-17
found_by: development (P5-REVIEW)
signature: aCancelNeverRemovesTheNextDownloadsFile
source: _app/_Sources/_Nhetrinh/_Browser/Page/Outside/_Downloads.swift on e7dccf9 (`end`, `remove(_:after:)`)
source: _app/Tests/NhetrinhTests/Page/Outside/_DownloadRaceTests.swift `aCancelNeverRemovesTheNextDownloadsFile`
source: nhetrinh_wt/REVIEW_P5.md (P5-REVIEW, outside the repository)
links: fix=yes lesson=no evidence=no toolgap=none

## Mechanism

A cancel freed the name in `reserved` at once and removed the file twice, now and 0.5 s later. The next download of the same name got that name; the late removal (or WebKit's own clean-up of the cancelled file at that path; which one: not proven) deleted the new, finished file.

## Confirm

The test: a held `race.txt` is cancelled, a second `race.txt` downloads at once: 1000 bytes at its end, gone 1 s later. Red 4 of 4 runs on e7dccf9 (P5-REVIEW).
