# NT-NAV-009 — A download quarantined as sandboxed, not as a web download — fix

id: NT-NAV-009
family: NAV
status: OBSERVED
date: 2026-11-17
source: _app/_Sources/_Nhetrinh/_Browser/Page/Outside/_Downloads.swift (`downloadDidFinish`)
source: _app/_Sources/NhetrinhCore/_Navigation/Downloads/Quarantine.swift
source: _app/Tests/NhetrinhTests/Page/Outside/DownloadGuardTests.swift
links: fix=yes lesson=no evidence=no toolgap=none

## Fix that holds (P5-FIX-1, p5/review, not on master)

`Quarantine.mark` on the finished partial file, before it gets its name: type web download, agent nhetrinh, the file's URL and its page. macOS keeps the type and the agent but drops the two URLs; "Where from" is a second attribute since P5-FIX-2 (NT-NAV-013).

## Wrong fixes

none

## Proof

`aFinishedDownloadIsQuarantined` (Core) red on a stub; `aDownloadIsPartialUntilDoneThenQuarantined` red when the mark is taken out, green with it. Read back: not yet (check the attribute of R31's file).
