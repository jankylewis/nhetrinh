# NT-NAV-003 — Camera answer kept per host

id: NT-NAV-003
family: NAV
status: OBSERVED
date: 2026-11-16
signature: aSiteIsAnOrigin
source: _app/_Sources/_Nhetrinh/_Browser/Page/Panels.swift on p3/pages 1d391d9 (`origin.host` only)
source: P3-REVIEW finding P1 (the review notes are kept outside the repository)
links: fix=yes lesson=no evidence=no toolgap=none

## Mechanism

Camera and microphone answers were keyed by `origin.host`: scheme and port were dropped. An Allow for
`http://127.0.0.1:8000` answered every port of that host and its `https://`; every `file:` page shared "".

## Confirm

From the code; `SitePermissionsTests.aSiteIsAnOrigin` is red under a mutation that keys by host again.
