# NT-BUG-001 — Search cut off at & — fix

id: NT-BUG-001
family: NAV
status: FIXED
date: 2026-11-16
source: _app/_Sources/NhetrinhCore/_AddressParser.swift `queryValueAllowed`
links: fix=yes lesson=no evidence=no toolgap=none

## Change

Encode the search text with `urlQueryAllowed` minus `& + = ? #`, so the whole text stays one `q=` value.

## Proof

`swift test`: `textBecomesOneSearchQuery` covers `rock & roll`, `c++ = fast?`, `issue #12`; all pass.
Not proven: a red run of these cases against the old encoding (the test was written with the fix).

## Proof on master (0f99aee)

`hubs/failures/evidence/readback/_LATEST.md` (2026-11-16 21:24, PASS 8 of 8; app 0.1.0 built from fba7d9e, whose app sources equal master 0f99aee), R4: `typed \`rock & roll\` and confirmed; the address bar held "https://www.google.com/search?q=rock%20%26%20roll"`. Red first stays not proven.
