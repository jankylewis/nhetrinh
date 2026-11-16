# NT-NAV-001 — Query value not escaped — fix

id: NT-NAV-001
family: NAV
status: FIXED
date: 2026-11-16
source: _app/_Sources/NhetrinhCore/_AddressParser.swift `queryValueAllowed`
links: fix=yes lesson=no evidence=no toolgap=none

## Fix that holds

Encode a single value with `urlQueryAllowed` minus `& + = ? #`. Covered by `textBecomesOneSearchQuery`.

## Wrong fix

Replacing spaces only (`%20`): `&` and `+` still break the query.

## Proof on master (0f99aee)

`hubs/failures/evidence/readback/_LATEST.md` (2026-11-16 21:24, PASS 8 of 8; app 0.1.0 built from fba7d9e, whose app sources equal master 0f99aee), R4: `the address bar held "https://www.google.com/search?q=rock%20%26%20roll"`. Red first stays not proven.
