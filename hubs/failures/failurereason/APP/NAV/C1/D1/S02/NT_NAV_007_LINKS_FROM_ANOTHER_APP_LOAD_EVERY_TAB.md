# NT-NAV-007 — Links from another app load every tab

id: NT-NAV-007
family: NAV
status: OBSERVED
date: 2026-11-17
signature: linksFromAnotherAppLoadOnlyTheShownTab
source: _app/_Sources/_Nhetrinh/_Browser/Page/Outside/BrowserWindowController+Outside.swift on e7dccf9 (`openIncoming`)
source: _app/Tests/NhetrinhTests/Page/Outside/IncomingTests.swift
source: nhetrinh_wt/REVIEW_P5.md (P5-REVIEW, outside the repository)
links: fix=yes lesson=no evidence=no toolgap=none

## Mechanism

`openIncoming` selected each new tab in turn; `select` loads a tab and the one before stays loaded. N links started N page processes at once, against R7 and the machine rule of 3 loading tabs.

## Confirm

The test: 3 links, 3 tabs loaded; 10 links, 10. Red on e7dccf9.
