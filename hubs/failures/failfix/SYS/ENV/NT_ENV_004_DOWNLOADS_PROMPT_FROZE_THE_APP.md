# NT-ENV-004 — The Downloads prompt froze the app — fix

id: NT-ENV-004
family: ENV
status: FIXED
date: 2026-11-17
source: _app/_Sources/NhetrinhCore/_Navigation/Downloads/_DownloadNamer.swift (`canWrite`)
source: _app/_Sources/_Nhetrinh/_Browser/Page/Outside/_Downloads.swift (`decideDestinationUsing`, the naming queue)
source: _app/_Sources/NhetrinhReadback/_Steps/Tabs/Pages/Downloads/DownloadFiles.swift (`download`: the probe stopped answering)
links: fix=yes lesson=no evidence=yes toolgap=none

## Fix that holds

The file is made empty and removed (`DownloadNamer.canWrite`, `O_CREAT | O_EXCL`) on the naming queue
before WebKit gets the URL: macOS asks there, the window keeps working, and the row stays "…" while it
asks. A refusal fails the row with "no access to the Downloads folder". The readback says NOT READ BACK
(the headmate allows the folder) when the row stays "…", fails with that reason, or the probe stops answering.

## Wrong fix

A longer readback wait: the app stays frozen for as long as the question is open.

## Proof

`canWriteMakesAndRemovesTheFile` red on a stub, green with the fix (test.sh). Readback 00:08 on the fixed
build: R31-R34 PASS, `end: the app quit when asked`. Not proven: that the fixed build stays responsive
while macOS asks. At 00:08 nobody was asked: by then the folder was allowed, and why is not known.
