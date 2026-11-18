# NT-NAV-006 — Running downloads hidden, a page downloads without asking — fix

id: NT-NAV-006
family: NAV
status: OBSERVED
date: 2026-11-17
source: _app/_Sources/NhetrinhCore/_Navigation/Downloads/DownloadList.swift on e7dccf9 (`shownItems`: the first 3)
source: _app/_Sources/_Nhetrinh/_Browser/_Window/BrowserWindowController+WebKit.swift (`shouldPerformDownload`)
links: fix=yes lesson=no evidence=no toolgap=none

## Fix that holds (P5-FIX-1, p5/review, not on master)

Ruling: every running download has a row with Cancel (the footer scrolls); a page that starts more than 5 downloads without a click or key in it (`DownloadGate`, 5 s) is asked once in a sheet; the answer holds for that page; downloads that come meanwhile wait for it.

## Wrong fixes

Raising the row count: a page can still outrun it.

## Proof

`everyRunningDownloadCanBeCancelled`, `everyRunningDownloadHasARow`, `unclickedDownloadsAskPastFive`, `theSixthUnclickedDownloadAsks` green; the last red under a mutation that lets every download go. Not read back.
