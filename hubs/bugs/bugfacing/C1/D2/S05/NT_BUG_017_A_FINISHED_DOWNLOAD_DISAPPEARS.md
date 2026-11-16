# NT-BUG-017 — A finished download disappears

id: NT-BUG-017
family: NAV
status: OBSERVED
date: 2026-11-17
signature: aCancelNeverRemovesTheNextDownloadsFile
source: _app/_Sources/_Nhetrinh/_Browser/Page/Outside/_Downloads.swift on p5/downloads e7dccf9 (`end`, `remove(_:after:)`)
source: _app/Tests/NhetrinhTests/Page/Outside/_DownloadRaceTests.swift `aCancelNeverRemovesTheNextDownloadsFile`
observed: found by the P5 adversarial review (code read, then a test with real downloads); no user report
links: fix=yes lesson=no evidence=no toolgap=none
cause: NT-NAV-005

## Steps

Start a download of `x.zip` and cancel it from its footer row; download `x.zip` again at once.

Expected: the second `x.zip` is in ~/Downloads, complete.
Actual (e7dccf9, from the test): the row says "done", and within a second the file is gone.

Not run on the installed app (the unit test drives real `WKDownload`s from a loopback server).
