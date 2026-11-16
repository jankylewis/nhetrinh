# Decisions and open questions

One row per decision, with who decided and when. A changed decision gets a new row; the old
row stays and is marked "replaced by".

## Decided

| Id | Decision | Decided by | Date |
|---|---|---|---|
| D1 | macOS only | headmate | 2026-11-16 |
| D2 | Engine: WebKit (`WKWebView`). Measured against Chromium (CEF): about half the memory, about 1/15 of the idle CPU, same startup, 516 KB against 331 MB on disk (`hubs/product/rnd/_bench/results/_RESULTS.md`). The speed benchmarks were not run | measured; headmate chose to skip the speed runs | 2026-11-16 |
| D3 | Shell: Swift + AppKit. No SwiftUI. No third-party packages | agent proposal, headmate agreed | 2026-11-16 |
| D4 | The vertical tab sidebar is the main navigation | headmate | 2026-11-16 |
| D5 | Icon: Hirono, pixel style, no background, as large as the canvas allows | headmate | 2026-11-16 |
| D6 | The repository is public and the agent owns it: commit, push, CI, merge | headmate | 2026-11-16 |
| D7 | Folders: exactly one entry starts with `_` (the most critical one); 5 entries at most; past 5, group by meaning | headmate | 2026-11-16 |
| D8 | Learnings live in `hubs/`, after the pattern of the headmate's other app | headmate | 2026-11-16 |
| D9 | Readback is part of "done": the builder uses the real app as the end user, through a tool the builder writes | headmate (term); agent (tool design) | 2026-11-16 |
| D10 | Benchmarks and readbacks must not load the headmate's machine (NT-ENV-001) | headmate | 2026-11-16 |
| D11 | The plan is kept in `hubs/product/plan/` | headmate | 2026-11-16 |
| D12 | One PR per phase; self-merge when CI is green and the readback passes | agent, as owner | 2026-11-16 |
| D13 | Version per phase: 0.1.0 (P0) to 0.8.0 (P7), then 1.0.0 (P8) | agent, as owner | 2026-11-16 |
| D14 | The plan (P0 to P8) is approved. The harness comes first: P0 is finished before any feature work | headmate | 2026-11-16 |
| D15 | A1, A2, A3 below are accepted with the plan | headmate ("plan approved") | 2026-11-16 |
| D16 | The briefing file is `CLAUDE.md` at the root (not `AGENTS.md` + `.claude/CLAUDE.md`): the fleet tool refuses to start a mate without it, the fleet is Claude-only, and the root has one free slot. Replaces the file names in A2 | agent, as owner | 2026-11-16 |
| D17 | The work is done by a fleet: the agent is the matemaster (steers, reviews, runs the readback, ships) with 2 mates, each in its own worktree | headmate | 2026-11-16 |
| D18 | The readback acts only through the Accessibility API (press, set value, confirm). It never moves the mouse or types keys, starts the app without taking the focus, and uses its own browsing profile | agent, as owner | 2026-11-16 |
| D19 | Settings Hub: one small native window, ⌘, (nhetrinh > Settings Hub…), holding Appearance (System, Light, Dark; headmate request: dark and light theme), Search engine, Unload idle tabs after N minutes, Clear Website Data. Replaces "no settings window in v1". Planned, not built (D14): scheduled in P4 (`M2_REAL_SITES_WORK.md`); may move to P2 if the headmate asks | headmate | 2026-11-16 |
| D20 | The bundle icon on a tile while the app is not running (pinned Dock item, Finder, Launchpad) is accepted, like the headmate's other apps: no Xcode, no Icon Composer. Closes the known limit of NT-BUG-002 | headmate | 2026-11-16 |
| D21 | The fleet tool's onboarding row 8 (needs an ADO epic) is ignored for this personal project | headmate | 2026-11-16 |
| D22 | P1 preparation may start before P0 closes: failing tests only, in `NhetrinhCore` only, no change to the app's behaviour. Narrows D14 for this one case | headmate | 2026-11-16 |
| D24 | The next phase's failing tests (`NhetrinhCore` only, stub types, no change to the app) may be written while the current phase is built. Widens D22 to every phase; first used by P2-PREP-1 | agent, as owner | 2026-11-16 |

## Assumed, then accepted with the plan (D15)

Proposed by the agent; accepted as a group when the headmate approved the plan.

| Id | Assumption | If the headmate says no |
|---|---|---|
| A1 | Caps: `.md` 100 lines; `.swift` and other code 150 lines; function 30 lines; line 120 characters; 5 parameters | change the numbers in `_app/scripts/conventions/sizes.py` (read by `conventions/_check.py`); nothing else moves |
| A2 | `rnd/` moves to `hubs/product/rnd/`, so `AGENTS.md` can sit at the root (5 root entries) | keep `rnd/` at the root and put the agent files only under `.claude/` |
| A3 | The readback tool drives the app through macOS Accessibility; this needs one permission grant for the terminal | weaker checks from inside the app, reported as such (risk R-1) |

## Open questions

| Id | Question | Default if no answer |
|---|---|---|
| Q1 | Confirm A1, A2, A3 | closed by D15 |
| Q2 | Tab folders (P7): inside 1.0, or after 1.0? | inside 1.0 |
| Q3 | Web Inspector: public API only (inspect from Safari), or also "Inspect Element" inside nhetrinh through a private WebKit key? | public API only |
| Q4 | Default search engine | Google (as today) |
| Q5 | Bad certificate: error page only, or a "proceed anyway" button? | error page only |
| Q6 | Order: is P3 (page basics) wanted before P2 (sidebar polish)? | P2 first, as planned |

## Known limits of a WebKit app (expected; each is checked in the phase named)

| Limit | Checked in |
|---|---|
| No browser extensions | by design |
| Password autofill from Safari / iCloud may not work in a third-party WebKit app | P3 |
| Some sites refuse sign-in from non-Safari WebKit apps | P3 |
| Find shows found / not found, no match count | P4 |
| Sites that work only in Chrome do not work | by design |
| A downloaded copy shows the macOS "unidentified developer" warning (not notarized) | P8 |

## Ideas the agent may propose later (not in the plan)

Address-bar suggestions from open tabs; pinned tabs; a "copy URL" shortcut; a memory readout
per tab in the sidebar. None is built without a headmate request.
