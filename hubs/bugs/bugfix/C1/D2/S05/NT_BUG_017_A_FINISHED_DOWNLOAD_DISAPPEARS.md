# NT-BUG-017 — A finished download disappears — fix

id: NT-BUG-017
family: NAV
status: OBSERVED
date: 2026-11-17
source: _app/_Sources/_Nhetrinh/_Browser/Page/Outside/_Downloads.swift (`cancel(row:)`, P5-FIX-1)
source: _app/_Sources/_Nhetrinh/_Browser/Page/Outside/Downloads+Naming.swift (`reserve`, `free`)
links: fix=yes lesson=no evidence=no toolgap=none

## Change

A download writes `<name>.download`; a cancel removes that file and keeps the name taken until WebKit's
`cancel` completion, then removes it again and frees the name (NT-NAV-005, NT-NAV-010).

## Proof

`aCancelNeverRemovesTheNextDownloadsFile` red 4 of 4 on e7dccf9 (P5-REVIEW), green after P5-FIX-1
(test.sh). Not read back. Not on master.
