# NT-GAT-013 — A download test raced a probe file

id: NT-GAT-013
family: GAT
status: OBSERVED
date: 2026-11-17
signature: aDownloadIsPartialUntilDoneThenQuarantined
source: nhetrinh_wt/REVIEW_P8_SIDE.md, part (a)
source: _app/_Sources/NhetrinhCore/_Navigation/Downloads/_DownloadNamer.swift:23-29 (`canWrite`)
source: _app/_Sources/_Nhetrinh/_Browser/Page/Outside/_Downloads.swift:54-80 (`decideDestinationUsing`: `canWrite`, then the rename, then the path)
source: _app/Tests/NhetrinhTests/Page/Outside/DownloadGuardTests.swift (`partialFile`)
observed: the test failed once in a 34 s test.sh run; its message was not kept
links: fix=no lesson=no evidence=no toolgap=none

## Mechanism

The test waited at most 10 s (`eventually`'s default) for a fresh `.nonPersistent()` web view,
which starts WebKit's processes, then read the folder twice. `canWrite` makes and removes an empty
`race.txt.download` before WebKit gets the path: the first read could see it, the second list `[]`.
Not proven: which of the two failed (no message kept).

## Confirm

By reading the code (review, part a). The race is not reproduced on demand.

## Fix

No clock: the test waits for the row's rename to `race.txt`, which `_Downloads.swift` does after
`canWrite` and right before it hands WebKit the path; then each look reads the folder once and the
check uses that same read. Every wait is capped at 120 s (`coldWebKit`), only to end a hang.
`test.sh` green twice after the change; not proven: that the flake is gone (it was rare).
