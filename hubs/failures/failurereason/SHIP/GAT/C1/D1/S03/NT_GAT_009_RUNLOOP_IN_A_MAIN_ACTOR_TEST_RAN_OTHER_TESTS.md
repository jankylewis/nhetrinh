# NT-GAT-009 — RunLoop in a main-actor test ran other tests

id: NT-GAT-009
family: GAT
status: OBSERVED
date: 2026-11-16
signature: exited with unexpected signal code 5
source: test.sh run of P2-BUILD-1 (draft `TabHandlingTests`, before the fix): `Fatal error: Index out of range`, NhetrinhTests
links: fix=yes lesson=no evidence=no toolgap=none

## Mechanism

Swift Testing runs `@MainActor` tests as jobs on the main queue. A draft test waited for the
probe's `.menu` action (performed on the next main-queue turn) with `RunLoop.main.run(until:)`.
That run drains the main queue, so other `@MainActor` tests started inside it, nested; the
run crashed with `Index out of range` (signal 5) and two cases saw rows of another browser.

## Confirm

The crash and the stray rows were gone once the tests pressed the menu item at once
(`performActionForItem`) and no test ran the run loop. Not proven: which test indexed out of range
(the log names none).
