# NT-NAV-010 — A partial download under its final name

id: NT-NAV-010
family: NAV
status: OBSERVED
date: 2026-11-17
signature: race.txt.download
source: _app/_Sources/_Nhetrinh/_Browser/Page/Outside/_Downloads.swift on e7dccf9 (`decideDestinationUsing`: the final name)
source: nhetrinh_wt/REVIEW_P5.md (P5-REVIEW, outside the repository)
links: fix=yes lesson=no evidence=no toolgap=none

## Mechanism

WebKit wrote straight to the final name. After a quit or a crash mid-download a truncated `x.pdf` looked complete. Read from the code (P5-REVIEW F6); not run.

## Confirm

From the code; P5-FIX-1's test sees `race.txt.download` while it runs.
