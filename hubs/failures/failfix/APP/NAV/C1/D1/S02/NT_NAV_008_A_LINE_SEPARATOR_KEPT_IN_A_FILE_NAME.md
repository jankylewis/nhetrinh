# NT-NAV-008 — A line separator kept in a file name — fix

id: NT-NAV-008
family: NAV
status: OBSERVED
date: 2026-11-17
source: _app/_Sources/NhetrinhCore/_Navigation/Downloads/_DownloadNamer.swift on e7dccf9 (`clean`)
links: fix=yes lesson=no evidence=no toolgap=none

## Fix that holds (P5-FIX-1, p5/review, not on master)

`clean` also removes `CharacterSet.newlines`.

## Wrong fixes

none

## Proof

Green after P5-FIX-1 (test.sh).
