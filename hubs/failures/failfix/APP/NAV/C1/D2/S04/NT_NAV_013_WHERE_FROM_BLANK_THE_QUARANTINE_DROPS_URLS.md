# NT-NAV-013 — Where from is blank: the quarantine drops the URLs — fix

id: NT-NAV-013
family: NAV
status: OBSERVED
date: 2026-11-17
source: _app/_Sources/NhetrinhCore/_Navigation/Downloads/Quarantine.swift (`setWhereFroms`, P5-FIX-2)
source: _app/Tests/_NhetrinhCoreTests/_Navigation/Downloads/DownloadGuardTests.swift `aDownloadSaysWhereItCameFrom`
links: fix=yes lesson=no evidence=yes toolgap=none

## Fix that holds

`Quarantine.mark` also writes `com.apple.metadata:kMDItemWhereFroms`: a binary property list of URL
strings, the file's URL then the page's (as Safari), each once, with no user name or password. The
quarantine keeps its URLs too (harmless, in case a later macOS keeps them).

## Wrong fix

Passing the URLs as strings or `NSURL` to the quarantine: tried, still dropped.

## Proof

`aDownloadSaysWhereItCameFrom` (4 cases: page and file, file only, credentials removed, page equal to the
file) red on 5c025ee, green with the fix (test.sh). Not proven: that Finder and Spotlight show it. `mdls`
gave `(null)` even for an attribute written by hand with `xattr`, in ~/Downloads after `mdimport`, so it is
no check on this machine. Not read back (the next readback comes with P8).
