# NT-NAV-009 — A download quarantined as sandboxed, not as a web download

id: NT-NAV-009
family: NAV
status: OBSERVED
date: 2026-11-17
found_by: development (P5-REVIEW)
signature: aDownloadIsPartialUntilDoneThenQuarantined
source: _app/_Sources/_Nhetrinh/_Browser/Page/Outside/_Downloads.swift (`downloadDidFinish`)
source: _app/_Sources/NhetrinhCore/_Navigation/Downloads/Quarantine.swift
source: _app/Tests/NhetrinhTests/Page/Outside/DownloadGuardTests.swift
source: nhetrinh_wt/REVIEW_P5.md (P5-REVIEW, outside the repository)
links: fix=yes lesson=no evidence=no toolgap=none

## Mechanism

The app set no quarantine. In the test host WebKit's sandboxed network process marks its files itself: `0083;…;;` with `LSQuarantineType` = `LSQuarantineTypeSandboxed`, no agent, no source. Safari marks a download as a web download from its site. On the installed app: not proven.

## Confirm

P5-FIX-1, with the app's mark taken out: the downloaded file reads `LSQuarantineTypeSandboxed`; with it: `LSQuarantineTypeWebDownload`, agent `nhetrinh`.
