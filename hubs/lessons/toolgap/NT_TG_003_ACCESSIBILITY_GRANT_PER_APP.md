# NT-TG-003 — Accessibility grant is per app

id: NT-TG-003
family: GAT
status: OPEN
date: 2026-11-16
source: brief P0-RBK-3 (2026-11-16): `AXIsProcessTrusted` false in an agent session although the terminal app is switched on in Accessibility
source: `_app/_Sources/NhetrinhReadback/Driver/_AX.swift` (`AXNode.isTrusted`)
source: brief P0-SIGN-1 (2026-11-16): grants dropped after a rebuild of the ad-hoc signed readback app, seen 19:09
source: `hubs/failures/evidence/readback/_LATEST.md` (19:51, commit 4a745ed): R1, R3-R7 "no element", R2 0 Dock items
source: `hubs/failures/evidence/readback/_LATEST.md` (20:01, commit 4b6a7c3): R1, R3-R7 still FAIL "no element", R2 empty
observed: 2026-11-16 brief P0-FIX-5, read only: `codesign -d -r-`, TCC.db row, `csreq -t`, `log show` of tccd 19:39-19:41 and 19:51-19:53
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
Since 19:29 the identity exists (certificate notBefore 12:29 UTC, SHA-1 `E325…6B85`), and
the installed readback app is signed with it (`Authority=nhetrinh local signing`, signed 19:51:07).

## Readback 19:51: grant kept, reads empty (brief P0-FIX-5, read only)

- Designated requirement of the installed readback app (`codesign -d -r-`): `identifier
  "io.github.jankylewis.nhetrinh.readback" and certificate leaf = H"e325…6b85"`; valid on disk.
- The TCC rows (system TCC.db, Accessibility 19:39:31, Screen Recording 19:40:02, `auth_value` 2)
  hold a `csreq` that decodes (`csreq -r- -t`) to the same requirement, and `codesign -v -R` says
  the installed app satisfies it. So the 19:34 build that got the grant at 19:39 was already signed
  with the same certificate: TCC stores the requirement of the code it granted. Its binary is gone
  (rebuilt in place), so its cdhash is not proven.
- tccd's log: in both runs (19:40 and 19:51) every Accessibility check of the readback app, asked
  by itself, by nhetrinh and by the Dock, ended `authValue=2` (allowed). The app logged
  `NSAccessibility Request Received` at 19:51 but no `accessibilityPerformAction`, which it logged at 19:40.
- So the signed rebuild did NOT lose the grant in TCC: the record, the requirement and the
  decisions all match. Why the reads came back empty is not proven; the readback did not record
  the read errors then. A re-grant (off and on, or remove and add) is the workaround to try.

## Readback gap closed (P0-FIX-5)

A window with no child or 0 Dock items read is a refused read: the step is NOT READ BACK
`Accessibility reads are empty: re-grant nhetrinh-readback.app (…, read error <AXError>)`, never
FAIL (`EmptyReads` in `_Steps/Step.swift`; tests in `_Dock/EmptyReadsTests.swift`). R7 now reads
the row count once more after the wait instead of reporting -1. The read error of the window's
children is in the reason, so the next empty run says why.
At 20:01 the window had children but no `nhetrinh.*` identifier, so R1, R3-R7 still said FAIL.

## Readback gap closed (P0-FIX-6)

An element is FAIL only when another `nhetrinh.*` identifier is in the window. None at all: NOT READ
BACK `none of the app's identifiers (nhetrinh.*) is in the window, its tree was not read (window
"<title>", <n> children, first roles [...], read error <AXError>)` (`WindowRead` in `_Steps/Step.swift`,
tests `missingElement`, `notReadTreeSaysWhatWasRead`; red under the old rule, checked by mutation).
Not proven on the app (no rebuild, no run since).
At 20:07 the "window" read was not a window (children AXApplication, AXMenuBar): NT-GAT-008.

## Remedy: the readback probe (P0-PROBE-1, D23; written, not run on the app)

source: brief P0-PROBE-1 (2026-11-16): the fleet waited 75 min for re-grants after rebuilds
R1, R3-R7 no longer use Accessibility. The readback starts nhetrinh with `NHT_READBACK=1`; only then
the app opens a Unix socket in a 0700 folder of its own (`ProbeServer`, `NhetrinhCore/Probe/`) and
answers state and actions through the user's own paths (`BrowserWindowController+Probe.swift`).
So these steps need no grant and run from any terminal; a rebuild of the readback app touches only R2.
Checked by tests, not by a run: socket round trip, folder 0700 and socket 0600, a malformed line
answered `failed` with the server still up (`ProbeSocketTests`); the menu item, the address field and a sidebar click
(`ProbeAnswerTests`); refused action FAIL, unreachable probe NOT READ BACK (`ProbeReplyTests`).
Each was red under a mutation (P0-PROBE-1 state file). The AX window reads (`WindowRole`,
`EmptyReads.missing`, `Fresh` retry; NT-GAT-006, NT-GAT-008) are removed with their tests.
Not proven: the refusal of another user's peer (`getpeereid`, no test); that the installed app answers it (needs install and a launch on the app seat); that R2
still reads the Dock when run as `nhetrinh-readback.app` (unchanged code, not re-run).
