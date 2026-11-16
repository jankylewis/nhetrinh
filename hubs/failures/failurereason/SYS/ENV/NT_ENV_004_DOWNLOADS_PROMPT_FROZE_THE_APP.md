# NT-ENV-004 — The Downloads prompt froze the app

id: NT-ENV-004
family: ENV
status: FIXED
date: 2026-11-17
signature: R31 FAIL: /download/attachment: no download row (downloads []
signature: end: the app did not quit within 5 s; the readback ended its own instance
source: _app/_Sources/_Nhetrinh/_Browser/Page/Outside/_Downloads.swift on p5/downloads 8d7a747 (`decideDestinationUsing`)
source: hubs/failures/evidence/readback/_LATEST.md (readback 00:08 on the fixed build)
observed: readback 23:53 to 23:59 on 2026-11-16, screen locked: R31-R34 FAIL, the app hung until signal 9
links: fix=yes lesson=no evidence=yes toolgap=none

## Mechanism

macOS asks once before an app writes into ~/Downloads, and holds the asking thread until the question
is answered. The app gave WebKit the destination; WebKit then made a sandbox extension for that path on
the **main thread** (`sample`: `DownloadClient::decideDestinationWithSuggestedFilename` >
`SandboxExtension::createHandle` > `_sandbox_extension_issue` > `__mac_syscall`, 1581 of 1581 samples).
With nobody at the locked screen, the app froze: no probe answer, no quit. The readback's wait kept the
last state it had read (before the row), so it said "no download row".

## Confirm

During a download, `sample <pid> 2`: is the main thread in `_sandbox_extension_issue`? The probe stops
answering and the app does not quit when asked.
