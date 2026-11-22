# nhetrinh — development plan

status: ACTIVE, approved by the headmate on 2026-11-16
written: 2026-11-16
owner: the agent (repo owner by headmate grant, see `DECISIONS.md` D6)

## Goal

A very small macOS browser: browse sites, a vertical tab sidebar, the basics.
Lightness first, speed second. After 1.0, features are added only when the headmate asks.

## Where we are (2026-11-19)

- `master`: P0-P7 merged (2026-11-18). P8 (1.0) waits on R2 and the icon ruling.
- After 1.0, by headmate request, on branches (none merged, none read back): P9 `p9/remember`, P10
  `p10/profile`, P11 `p11/history` (holds P9; the installed build). Merge order: P9, P10, P11.
- Nothing below is "done" until its readback passes.

## Phases

| Phase | Version | Size | What the headmate gets | Status | Detail |
|---|---|---|---|---|---|
| P0 Foundation | 0.1.0 | L | conventions checked by tool, agent harness, readback tool, open bugs closed | DONE (readback 8/8, 2026-11-16 21:24, `hubs/failures/evidence/readback/_LATEST.md`) | `M1_DAILY_DRIVER.md` |
| P1 Tab lifecycle | 0.2.0 | M | tabs come back after quit; a playing tab is never unloaded | DONE (merged #4, tag v0.2.0; its steps PASS in the full readback of 2026-11-17 13:19 and 13:57, `_LATEST.md`; R2 is open on P8 as NT-GAT-015) | `M1_DAILY_DRIVER.md` |
| P2 Sidebar and tabs | 0.3.0 | M | close on hover, reorder, reopen, favicons, stop, background tabs | DONE (merged #5, tag v0.3.0; its steps PASS in the full readback of 2026-11-17 13:19 and 13:57, `_LATEST.md`; R2 is open on P8 as NT-GAT-015) | `M1_DAILY_DRIVER.md` |
| P3 Page basics | 0.4.0 | L | dialogs, file upload, error page, sign-in, camera, print, app links | DONE (merged #6, tag v0.4.0; its steps PASS in the full readback of 2026-11-17 13:19 and 13:57, `_LATEST.md`; R2 is open on P8 as NT-GAT-015) | `M2_REAL_SITES_WORK.md` |
| P4 Find, zoom, tools | 0.5.0 | M | find in page, zoom per site, search engine choice, clear data | DONE (merged #7, tag v0.5.0; its steps PASS in the full readback of 2026-11-17 13:19 and 13:57, `_LATEST.md`; R2 is open on P8 as NT-GAT-015) | `M2_REAL_SITES_WORK.md` |
| P5 Downloads, app links | 0.6.0 | M | files to ~/Downloads; links from other apps open here | DONE (merged #8, tag v0.6.0; its steps PASS in the full readback of 2026-11-17 13:19 and 13:57, `_LATEST.md`; R2 is open on P8 as NT-GAT-015) | `M2_REAL_SITES_WORK.md` |
| P6 Memory guard | 0.7.0 | S | memory given back at once under pressure | DONE (merged #9, tag v0.7.0; its steps PASS in the full readback of 2026-11-17 13:19 and 13:57, `_LATEST.md`; R2 is open on P8 as NT-GAT-015) | `M3_V1_RELEASE.md` |
| P7 Tab groups | 0.8.0 | L | collapsible tab groups in the sidebar | DONE (merged #10, tag v0.8.0; its steps PASS in the full readback of 2026-11-17 13:19 and 13:57, `_LATEST.md`; R2 is open on P8 as NT-GAT-015) | `M3_V1_RELEASE.md` |
| P8 Release 1.0 | 1.0.0 | S | downloadable build on GitHub Releases | DOING (P8-BUILD-1: release.yml, notes, README, R44; P8-FIX-1: review fixes; P8-MIN-1: Window > Minimize ⌘M, R46, tests green, not read back; P8-FONT-1: the interface in Menlo, R47, tests green, not read back; P8-CHROME-1: toolbar Toggle Sidebar, toolbar clears the traffic lights (NT-BUG-018), R48, tests green, not read back; P8-GROUPS-1: nested tab groups, 4 levels, full CRUD, session v3, R49, tests green, not read back; P8-SIDE-1: the sidebar on the left or the right (Settings Hub > Sidebar position), R50, tests green, not read back; no release yet) | `M3_V1_RELEASE.md` |
| P9 Remember sign-ins | - | M | sign-ins survive quit and update (D28; P9-REMEMBER-2: one Keychain item per signing kind) | DOING (`p9/remember` 786a582, tests green; R51 not read back) | `DECISIONS.md` D28 |
| P10 Profile folders | - | M | one folder per profile; Show data folder, Reset profile (D29) | DOING (`p10/profile` 40d0cbf, tests green; R53 not read back) | `DECISIONS.md` D29 |
| P11 History | - | M | address-bar dropdown from history and open tabs (D30); Duplicate Tab, Put Tab to Idle | DOING (`p11/history`, installed cd9b848; R51, R52, R54, R55 PASS 2026-11-22) | `DECISIONS.md` D30 |

Size is relative effort (S, M, L). No dates: a phase ends when its gate passes, not on a day.
Status: TODO, DOING, DONE. DONE needs the readback verdict file cited next to it.

## The gate (every phase, in this order)

1. Read `hubs/bugs/TRIAGE.md` and `hubs/failures/TRIAGE.md`. Write the phase's foreseen risks.
2. Write the failing tests first, in `NhetrinhCore`, parameterized.
3. Build the phase.
4. `python3 _app/scripts/conventions/_check.py`: 0 violations.
5. `nice -n 10 _app/scripts/test.sh`: all green (never plain `swift test`, NT-GAT-001). The report quotes the count.
6. `_build.sh`, then `install/_install.sh` (the readback runs on the installed app, never on the build folder).
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
| `nhetrinh.app` on disk | 1 MB | 1,032 KB (2026-11-19, P11: over; cut or new number, headmate) |
| Idle CPU, tabs open, nothing playing | 2 % | 1.3 % (10 sites) |
| 3 tabs opened, 2 unloaded (P6, R38): app, and app + helpers | one-tab budget + 15 MB (55 MB, 125 MB) | not measured yet |

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
| R-1 | Accessibility permission is not granted, so the readback tool cannot drive the app | P0 asks once. Without it: weaker in-app checks, reported as such. Since D23 only R2 needs it |
| R-2 | macOS forgets permission grants when an ad-hoc signed app is rebuilt (seen 2026-11-16, NT-TG-003) | Sign with one stable local identity: `signing.sh` (written; not run, not proven) |
| R-3 | WebKit limits: no find match count; some sites refuse non-Safari WebKit apps | Listed as known limits; the user agent already ends like Safari's |
| R-4 | P7 (tab folders) is the largest phase | It can move after 1.0 without blocking it (`DECISIONS.md` Q2) |
| R-5 | A feature costs memory | The budget gate stops the phase |
| R-6 | P2: the link's menu is WebKit's own; the probe opens it with an in-app right click. The probe's in-app ⌘-click did not reach the page (23:00) | R17 says NOT READ BACK when no menu is seen; at 22:34 the menu opened and R17 PASS. ⌘-click: unit test `commandClickOpensABackgroundTab` only (ruling READBACK P2-2); a ⌘-click that does not arrive is said in R17's line, never NOT READ BACK; one that arrives wrong is a FAIL. Why it did not arrive: not proven |
| R-7 | P2: favicons fetch in the app process (URLSession) and keep images | 32 px each, 200 at most (800 KB); R8 22:34: app 30.5 MB with example.com's icon request (the P2 cost alone not measured) |
| R-8 | P2: ⌃⇥ / ⌃⇧⇥ may be taken by the web view before the menu; hover and drag are not read back (D18) | Tested on the menu items only; reported as not read back |
| R-9 | P6: WebKit may keep the page process of an unloaded tab (a process cache), so R36 sees more than 1 | R36 counts the page processes before and after; a cache is not proven or ruled out until R36 runs |
| R-10 | P6: a warning takes tabs idle past 1 min, so R36 and R37 wait 63 s each | Accepted: a warning sent at once proves nothing; R36 sends one at once too and expects no unload |
| R-11 | P7: a drag is not read back (D18); R40 and R49 move by the row menu (same tree move). Since P8-GROUPS-1 the outline reloads only when the tree's shape changes (unit tested, `GroupsTests`); the cost of a reload: not measured. A build before P8-GROUPS-1 keeps a version 3 session as `session.bad.json` (no downgrade planned) | Drops unit tested (`FoldersTests`, `GroupMenuTests`); R38 and R8 read the budget |

## Not in v1 (only when the headmate asks)

Bookmarks, history list, extensions, sync, password manager,
private window, more than one window, reader mode, content blocker, Intel build, notarization.

## How this plan changes

- A phase starts or ends: update its Status here and the status line in its milestone file.
- A decision or a changed number: one row in `DECISIONS.md` with the date and who decided.
- A phase is never deleted. Mark it MOVED or DROPPED with the reason.
