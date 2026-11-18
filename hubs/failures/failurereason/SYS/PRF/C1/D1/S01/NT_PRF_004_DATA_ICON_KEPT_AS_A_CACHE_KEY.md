# NT-PRF-004 — Data icon kept as a cache key

id: NT-PRF-004
family: PRF
status: OBSERVED
date: 2026-11-16
signature: aLargeDataHrefGivesNoIcon
source: _app/_Sources/NhetrinhCore/Tabs/FaviconURL.swift on p2/sidebar cc8affe (`resolve`: a `data:` href is returned as is)
source: _app/_Sources/_Nhetrinh/_Browser/Handling/Favicons.swift on cc8affe (`cache`, `missing`: keyed by the icon URL)
links: fix=yes lesson=no evidence=no toolgap=none

## Mechanism

A `data:` href is the icon itself. `resolve` returned it whatever its length, and `Favicons` keeps
up to 200 icons and 200 misses keyed by that URL: the whole href stays in memory as a key.
200 keys of 500 KB is about 100 MB, against the 2 MB the P2 exit allows favicons.

## Confirm

`FaviconURLTests.aLargeDataHrefGivesNoIcon` on cc8affe: hrefs of 64 KB and 500 KB give an icon URL.
From the code; the app's footprint with such pages not measured.
