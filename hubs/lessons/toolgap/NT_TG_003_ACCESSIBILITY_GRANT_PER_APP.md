# NT-TG-003 — Accessibility grant is per app

id: NT-TG-003
family: GAT
status: OPEN
date: 2026-11-16
source: brief P0-RBK-3 (2026-11-16): `AXIsProcessTrusted` false in an agent session although the terminal app is switched on in Accessibility
source: `_app/_Sources/NhetrinhReadback/Driver/_AX.swift` (`AXNode.isTrusted`)
source: brief P0-SIGN-1 (2026-11-16): grants dropped after a rebuild of the ad-hoc signed readback app, seen 19:09
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
rebuild changes the ad-hoc signature and macOS then drops the Accessibility and Screen Recording
grants (risk R-2, seen 2026-11-16 19:09, brief P0-SIGN-1).
A step without a grant is NOT READ BACK and names the app that lacks it: `nhetrinh-readback.app`
when run as that app, `the terminal app` otherwise (`Grant` in `Driver/AppSession.swift`, tests
`granteeIsTheAppThatRuns`, `missingGrantNamesTheGranteeAndNoPath`).
Not proven: a full run through the app (not launched yet; waits for the grant).

## Wanted: one stable local signing identity (written, not run)

`_app/scripts/install/signing.sh create` makes one self-signed code-signing identity
`nhetrinh local signing` in the login keychain, only if missing, after it printed the change and the
headmate typed yes. `readback_app.sh` signs with it when `signing.sh identity` finds it (ad hoc
otherwise); its SHA-1 joins `NHTSourceHash`, so the switch rebuilds once; with no identity the
hash is as before (checked by hand 2026-11-16, same 16 hex digits).
Not proven: the identity was not created (the keychain change waits for the headmate), `codesign`
with it, and that macOS keeps the grants over a rebuild signed with it.
