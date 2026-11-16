# NT-NAV-001 — Query value not escaped

id: NT-NAV-001
family: NAV
status: FIXED
date: 2026-11-16
signature: search cut off at &
source: _app/_Sources/NhetrinhCore/_AddressParser.swift
links: fix=yes lesson=no evidence=no toolgap=none

## Mechanism

`CharacterSet.urlQueryAllowed` is the set allowed in a whole query string, so it leaves `&`, `=`, `+`, `?`, `#` as they are.
Inside one value they are separators: `&` starts a new parameter, `+` means a space, `#` starts the fragment.

## Confirm

Search `a & b`; the result page shows a search for `a` only.
