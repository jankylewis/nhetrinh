# NT-NAV-002 — javascript: taken for another app — fix

id: NT-NAV-002
family: NAV
status: OBSERVED
date: 2026-11-16
source: _app/_Sources/NhetrinhCore/_Navigation/ExternalScheme.swift (`staying` + `javascript`, P3-FIX-1 merge)
links: fix=yes lesson=no evidence=no toolgap=none

## Fix that holds

`javascript` stays in the browser (`ExternalSchemeTests.javascriptStays`).

## Proof

P2's case red on the merge, green with the fix (P3-FIX-1, test.sh). Not read back. Not on master.
