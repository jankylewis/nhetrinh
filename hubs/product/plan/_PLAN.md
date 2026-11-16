# nhetrinh — development plan

status: ACTIVE, approved by the headmate on 2026-11-16
written: 2026-11-16
owner: the agent (repo owner by headmate grant, see `DECISIONS.md` D6)

## Goal

A very small macOS browser: browse sites, a vertical tab sidebar, the basics.
Lightness first, speed second. After 1.0, features are added only when the headmate asks.

## Where we are (2026-11-16)

- Engine chosen by measurement: WebKit. Numbers: `hubs/product/rnd/_bench/results/_RESULTS.md`.
- On `master` (`b07f437`): the two R&D MVPs, the benchmark and the icon.
- Features of the WebKit MVP, NT-FEAT-001 to 008: `../features/S01.md`.
- Local, not committed: the `_app/` scaffold, `hubs/`, the folder checker.
- Open hub items: NT-BUG-001, NT-BUG-002, NT-ENV-001, NT-TAB-001, NT-BLD-002, NT-TG-001, NT-TG-002.
- Order fixed by the headmate: the harness (P0) is finished before any feature work (D14).
- No readback has run yet. Nothing below is "done" until its readback passes.

## Phases

| Phase | Version | Size | What the headmate gets | Status | Detail |
|---|---|---|---|---|---|
| P0 Foundation | 0.1.0 | L | conventions checked by tool, agent harness, readback tool, open bugs closed | TODO | `M1_DAILY_DRIVER.md` |
| P1 Tab lifecycle | 0.2.0 | M | tabs come back after quit; a playing tab is never unloaded | TODO | `M1_DAILY_DRIVER.md` |
| P2 Sidebar and tabs | 0.3.0 | M | close on hover, reorder, reopen, favicons, stop, background tabs | TODO | `M1_DAILY_DRIVER.md` |
| P3 Page basics | 0.4.0 | L | dialogs, file upload, error page, sign-in, camera, print, app links | TODO | `M2_REAL_SITES_WORK.md` |
| P4 Find, zoom, tools | 0.5.0 | M | find in page, zoom per site, search engine choice, clear data | TODO | `M2_REAL_SITES_WORK.md` |
| P5 Downloads, app links | 0.6.0 | M | files to ~/Downloads; links from other apps open here | TODO | `M2_REAL_SITES_WORK.md` |
| P6 Memory guard | 0.7.0 | S | memory given back at once under pressure | TODO | `M3_V1_RELEASE.md` |
| P7 Tab folders | 0.8.0 | L | collapsible tab groups in the sidebar | TODO | `M3_V1_RELEASE.md` |
| P8 Release 1.0 | 1.0.0 | S | downloadable build on GitHub Releases | TODO | `M3_V1_RELEASE.md` |

Size is relative effort (S, M, L). No dates: a phase ends when its gate passes, not on a day.
Status: TODO, DOING, DONE. DONE needs the readback verdict file cited next to it.

## The gate (every phase, in this order)

1. Read `hubs/bugs/TRIAGE.md` and `hubs/failures/TRIAGE.md`. Write the phase's foreseen risks.
2. Write the failing tests first, in `NhetrinhCore`, parameterized.
3. Build the phase.
4. `python3 _app/scripts/conventions/_check.py`: 0 violations.
5. `nice -n 10 _app/scripts/test.sh`: all green (never plain `swift test`, NT-GAT-001). The report quotes the count.
6. `_build.sh`, then `install.sh` (the readback runs on the installed app, never on the build folder).
7. Readback: every step of this phase and of all earlier phases is PASS.
8. Lightness budget, measured inside the readback (table below).
9. Hubs in the same PR: feature rows, bug / failure / lesson / tool-gap entries, evidence paths.
10. One PR per phase. CI green, then self-merge, version tag, and a report to the headmate
    that says what each readback step did.

A step the readback cannot drive is reported as "not read back". It is never counted as passed.

## Lightness budget

| Measure | Budget | Today (R&D run) |
|---|---|---|
| App process, one simple tab | 40 MB | 34.5 MB |
| App + all helper processes, one simple tab | 110 MB | 95.7 MB |
| `nhetrinh.app` on disk | 1 MB | 516 KB |
| Idle CPU, tabs open, nothing playing | 2 % | 1.3 % (10 sites) |

A phase that breaks a budget stops. It ships only after the cost is removed, or the headmate
accepts a new number (recorded in `DECISIONS.md`).

## Machine rules (the headmate works on this Mac during every run)

- One app instance. At most 3 tabs loading. Pages load one after another.
- Builds and tools run at low priority (`nice`).
- Nothing that holds a CPU core for more than a minute without asking first.
- No capture of the screen. Only the app's own window or the Dock item's own rectangle.

## Risks

| Id | Risk | Answer |
|---|---|---|
| R-1 | Accessibility permission is not granted, so the readback tool cannot drive the app | P0 asks once. Without it: weaker in-app checks, reported as such |
| R-2 | macOS may forget permission grants when an ad-hoc signed app is rebuilt (not proven here) | Check in P3. If seen: sign with one stable local identity |
| R-3 | WebKit limits: no find match count; some sites refuse non-Safari WebKit apps | Listed as known limits; the user agent already ends like Safari's |
| R-4 | P7 (tab folders) is the largest phase | It can move after 1.0 without blocking it (`DECISIONS.md` Q2) |
| R-5 | A feature costs memory | The budget gate stops the phase |

## Not in v1 (only when the headmate asks)

Bookmarks, history list, address-bar suggestions, extensions, sync, password manager,
private window, more than one window, reader mode, content blocker, Intel build, notarization.

## How this plan changes

- A phase starts or ends: update its Status here and the status line in its milestone file.
- A decision or a changed number: one row in `DECISIONS.md` with the date and who decided.
- A phase is never deleted. Mark it MOVED or DROPPED with the reason.
