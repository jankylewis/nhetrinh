# NT-TG-003 — Accessibility grant is per app

id: NT-TG-003
family: GAT
status: OPEN
date: 2026-11-16
source: brief P0-RBK-3 (2026-11-16): `AXIsProcessTrusted` false in an agent session although the terminal app is switched on in Accessibility
source: `_app/_Sources/NhetrinhReadback/Driver/_AX.swift` (`AXNode.isTrusted`)
observed: `open -W -n <app>` returned 0 for a test app that exits 3 (2026-11-16, scratch app, not kept)
links: fix=no lesson=no evidence=no toolgap=NT-TG-003

## Gap

macOS grants Accessibility per app. The terminal's grant does not reach the session it starts,
so `swift run nhetrinh-readback` there cannot act on the app: every step is NOT READ BACK.
Not proven: which process macOS checks for a session started by an agent.

## Workaround

`_app/scripts/install/readback_app.sh` wraps the release binary into
`~/Applications/nhetrinh-readback.app` (id `io.github.jankylewis.nhetrinh.readback`, `LSUIElement`,
ad-hoc signed). The headmate grants it once. `readback_app.sh run [--steps ...]` launches it with
`open -W -n ... --args --evidence <repo> --log <file>`: `open` passes no stdout and does not return
the app's exit code, so the app writes both to the log, the code as its last line `exit: <code>`
(tests `logIsFoundBeforeTheCommandLineIsChecked`, `lastLogLineHoldsTheExitCode`). `--evidence`
refuses a path outside the repository (test `badAppFlagIsAUsageError`).
The app is rebuilt only when the hash of the readback sources changes (`NHTSourceHash`), because a
rebuild changes the ad-hoc signature and macOS may forget the grant (risk R-2, not proven).
Not proven: a full run through the app (not launched yet; waits for the grant).

## Wanted

One stable local signing identity, so a rebuild keeps the grant (R-2).
