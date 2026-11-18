# NT-NAV-006 — Running downloads hidden, a page downloads without asking

id: NT-NAV-006
family: NAV
status: OBSERVED
date: 2026-11-17
found_by: development (P5-REVIEW)
signature: everyRunningDownloadCanBeCancelled
source: _app/_Sources/NhetrinhCore/_Navigation/Downloads/DownloadList.swift on e7dccf9 (`shownItems`: the first 3)
source: _app/_Sources/_Nhetrinh/_Browser/_Window/BrowserWindowController+WebKit.swift (`shouldPerformDownload`)
source: nhetrinh_wt/REVIEW_P5.md (P5-REVIEW, outside the repository)
links: fix=yes lesson=no evidence=no toolgap=none

## Mechanism

The footer showed the first 3 rows and Cancel works on a shown row only; a 4th running download was kept but hidden. `<a download>` needs no click, so a page could loop `a.click()`: 100 downloads, 97 unseen and unstoppable until quit.

## Confirm

`everyRunningDownloadCanBeCancelled` (4, 100) red on e7dccf9: 3 shown with a Cancel.
