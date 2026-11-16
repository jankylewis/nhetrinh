# NT-BUG-001 — Search cut off at & — fix

id: NT-BUG-001
family: NAV
status: OBSERVED
date: 2026-11-16
source: _app/_Sources/NhetrinhCore/_AddressParser.swift `queryValueAllowed`
links: fix=yes lesson=no evidence=no toolgap=none

## Change

Encode the search text with `urlQueryAllowed` minus `& + = ? #`, so the whole text stays one `q=` value.

## Proof

`swift test`: `textBecomesOneSearchQuery` covers `rock & roll`, `c++ = fast?`, `issue #12`; all pass.
Not proven: a red run of these cases against the old encoding (the test was written with the fix).
