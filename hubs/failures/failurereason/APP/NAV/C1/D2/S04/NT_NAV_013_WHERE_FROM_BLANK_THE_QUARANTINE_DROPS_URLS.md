# NT-NAV-013 — Where from is blank: the quarantine drops the URLs

id: NT-NAV-013
family: NAV
status: OBSERVED
date: 2026-11-17
signature: aDownloadSaysWhereItCameFrom
source: _app/_Sources/NhetrinhCore/_Navigation/Downloads/Quarantine.swift on p7/prep 5c025ee (`mark`)
source: hubs/failures/evidence/readback/_LATEST.md (readback 01:15; R31's attribute read by the P5-VERIFY seat)
observed: R31's file: `com.apple.quarantine: 0081;…;;<UUID>`; its record in macOS's quarantine events: agent nhetrinh, type 0, download URL and page URL empty
links: fix=yes lesson=no evidence=yes toolgap=none

## Mechanism

`Quarantine.mark` passes the file's URL and the page's as `kLSQuarantineDataURLKey` and
`kLSQuarantineOriginURLKey` through `URLResourceValues.quarantineProperties`. On this macOS that call keeps
the type and the agent and drops both URLs: tried with Swift `URL`, `NSURL` and `String`, loopback and
https (P5-FIX-2, a scratch program outside the repository): read back nil, recorded empty. Why macOS drops
them: not proven. Finder's "Where from" does not come from the quarantine at all: it reads
`com.apple.metadata:kMDItemWhereFroms`, which Safari writes and the app did not.

## Confirm

`getxattr(file, "com.apple.metadata:kMDItemWhereFroms")` after `Quarantine.mark`: none before P5-FIX-2.
