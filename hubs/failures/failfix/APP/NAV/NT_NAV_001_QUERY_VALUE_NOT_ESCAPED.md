# NT-NAV-001 — Query value not escaped — fix

id: NT-NAV-001
family: NAV
status: OBSERVED
date: 2026-11-16
source: _app/_Sources/NhetrinhCore/_AddressParser.swift `queryValueAllowed`
links: fix=yes lesson=no evidence=no toolgap=none

## Fix that holds

Encode a single value with `urlQueryAllowed` minus `& + = ? #`. Covered by `textBecomesOneSearchQuery`.

## Wrong fix

Replacing spaces only (`%20`): `&` and `+` still break the query.
