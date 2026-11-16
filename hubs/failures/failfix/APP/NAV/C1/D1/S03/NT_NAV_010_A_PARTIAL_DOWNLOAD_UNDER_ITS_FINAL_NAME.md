# NT-NAV-010 — A partial download under its final name — fix

id: NT-NAV-010
family: NAV
status: OBSERVED
date: 2026-11-17
source: _app/_Sources/_Nhetrinh/_Browser/Page/Outside/_Downloads.swift on e7dccf9 (`decideDestinationUsing`: the final name)
links: fix=yes lesson=no evidence=no toolgap=none

## Fix that holds (P5-FIX-1, p5/review, not on master)

WebKit writes `<name>.download`; at the end it is renamed to its name. A name is free only when neither file is there.

## Wrong fixes

none

## Proof

`aDownloadIsPartialUntilDoneThenQuarantined` (the folder holds `race.txt.download` while it runs), `aPartialFileHasItsOwnName`. A quit mid-download: not run.
