# NT-BUG-001 — Search cut off at &

id: NT-BUG-001
family: NAV
status: OBSERVED
date: 2026-11-16
signature: search cut off at &
source: _app/_Sources/NhetrinhCore/_AddressParser.swift (query encoding)
source: _app/Tests/_NhetrinhCoreTests/_AddressParserTests.swift `textBecomesOneSearchQuery`
observed: found while moving the address parser into NhetrinhCore (scaffold, not reported by a user)
links: fix=yes lesson=no evidence=no toolgap=none
cause: NT-NAV-001

## Steps

Type `rock & roll` in the address bar and press Return.

Expected: a search for `rock & roll`.
Actual: the query string ends at `&`, so the search is for `rock ` only. Same for `+` (read as a space), `=`, `?`, `#`.

Status OBSERVED: fixed and tested in the scaffold, not yet on `master`.
