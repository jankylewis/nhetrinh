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
| D18 | The readback acts only through the Accessibility API (press, set value, confirm). It never moves the mouse or types keys, starts the app without taking the focus, and uses its own browsing profile. Narrowed by D23: only R2 still uses Accessibility | agent, as owner | 2026-11-16 |
| D19 | Settings Hub: one small native window, ⌘, (nhetrinh > Settings Hub…), holding Appearance (System, Light, Dark; headmate request: dark and light theme), Search engine, Unload idle tabs after N minutes, Clear Website Data. Replaces "no settings window in v1". Planned, not built (D14): scheduled in P4 (`M2_REAL_SITES_WORK.md`); may move to P2 if the headmate asks | headmate | 2026-11-16 |
| D20 | The bundle icon on a tile while the app is not running (pinned Dock item, Finder, Launchpad) is accepted, like the headmate's other apps: no Xcode, no Icon Composer. Closes the known limit of NT-BUG-002 | headmate | 2026-11-16 |
| D21 | The fleet tool's onboarding row 8 (needs an ADO epic) is ignored for this personal project | headmate | 2026-11-16 |
| D22 | P1 preparation may start before P0 closes: failing tests only, in `NhetrinhCore` only, no change to the app's behaviour. Narrows D14 for this one case | headmate | 2026-11-16 |
| D23 | Readback probe (P0-PROBE-1, NT-TG-003), narrows D18: only when started with `NHT_READBACK=1`, nhetrinh opens a Unix socket in a 0700 folder of its own under the user's temporary folder (socket 0600, peers of the same user only, never TCP, never in a normal launch). It answers `state` (window title and shown, sidebar rows, selected row and width, address text, menu shortcuts) and `navigate`, `newTab`, `closeTab`, `select`, each through the user's path: the address field's action, the File menu item performed, a row selected in the sidebar table. The readback uses it for R1, R3-R7 with no Accessibility; R2 keeps Accessibility; R8 launches without it. Unset: no socket, no thread; the code costs 72 KB (bundle 520 to 592 KB, P0-PROBE-1). Run on the app in P0-REV-PROBE (R1, R3-R7, R8 PASS; normal launch: no socket). P0-PROBE-FIX: a peer has 1 s for its whole line, not per read, and the gate is tested (NT-TG-003). Not proven: refusal of another user's peer | agent | 2026-11-16 |
| D24 | The next phase's failing tests (`NhetrinhCore` only, stub types, no change to the app) may be written while the current phase is built. Widens D22 to every phase; first used by P2-PREP-1 | agent, as owner | 2026-11-16 |
| D25 | Amends D18 (NT-TG-005): a readback step that WebKit refuses in a hidden page may bring nhetrinh to the front and take the focus: only R26a and R26b, only when the readback runs with `--allow-focus`; the step's report line says it took the focus. Without the flag they stay NOT READ BACK. R26a waits for nhetrinh's own site sheet, reads it, presses Don't Allow (the macOS camera prompt is never asked for, no system dialog is left on screen); PASS = the site sheet appeared with the site's name. R26b: fullscreen from a click the probe sends, the window is fullscreen, leave it, the window is back | agent, as owner | 2026-11-16 |
| D26 | The 1.0 lightness report is `hubs/product/rnd/LIGHTNESS_1_0.md`, next to the R&D baseline it is measured against: `hubs/product/plan/` holds 5 entries, each at 100 lines (P8-BUILD-1). Releases: a tag `v0.x` is published as a GitHub prerelease, never "latest"; `v1.0.0` and later are full releases (`release_notes.py --kind`, tested; `release.yml`) | agent, as owner; releases: headmate | 2026-11-17 |
| D27 | Tab groups nest: a group holds tabs and groups in any order, 4 levels at most (a top group and 3 inside), one constant; Folder is called Group in every menu, sheet and feature text (code names may stay); session version 3, versions 2 and 1 still read; full create, read, update, delete and readback R49 (P8-GROUPS-1, NT-FEAT-048 to 050) | headmate | 2026-11-17 |
| D28 | Remember sign-ins (P9-REMEMBER, headmate request: a sign-in was lost at every quit). Measured by the headmate: WebKit keeps dated cookies on disk but never a session cookie (no expiry). Settings Hub switch "Remember sign-ins after quit", default on (a `prefs.json` without the key reads as on). A clean quit (`applicationShouldTerminate` answers later, at most 3 s) keeps only the session cookies of the profile's data store as ONE login-Keychain generic-password item, service `io.github.jankylewis.nhetrinh.signins.<profile or default>`, account `signins.signed` for a build signed with an identity, `signins.adhoc` for an ad-hoc one, read from the app's own signature (round 2, headmate priority: sign-ins survive reinstalling a new build; `_build.sh` signs with the local identity of `install/signing.sh` when it exists, so the next build is the same app to the Keychain; else ad hoc, GitHub CI; an item another signature made can be neither read nor deleted, only overwritten, NT-BLD-006: a write updates in place, a refused delete empties the item; P9-REMEMBER-2: an item first kept by an ad-hoc build was unreadable by a signed one forever, so the two kinds never share an item, and a run whose launch read is refused access (status -25293, -25243, -25244 or -25308) writes nothing at its quit and logs why with counts only), never synchronized; the next launch sets them back before the first tab loads (at most 3 s, then the tabs open anyway) and deletes the item. A marker file next to the session, written at launch and removed at a clean quit, found at launch means a crash: nothing restored, the item deleted. A quit while the cookies are still being set is clean and leaves the item. Switch off or Clear All: the item is deleted. Logs and readback carry counts and error kinds only. Keychain calls run with user interaction off (`SecKeychainSetUserInteractionAllowed`; `LAContext` does not cover the login Keychain's access list): a call that would ask fails, logged by status (REVIEW_P9_REMEMBER.md, RECHECK_P9_REMEMBER.md). Sign-ins survive an update when both builds are signed with the local identity; an ad-hoc build keeps its own (not proven until read back). Cost of P9-REMEMBER-2: the item under the old account `signins` is left as it is, so sign-ins kept by 77ee8f5 or earlier are not restored once. The new signature also makes nhetrinh a new app once for its privacy grants (camera, microphone, Downloads). Unit tests reach only in-memory seams (`HeldSecrets`, `HeldJar`); the real Keychain and cookie-store seams refuse outside the app | headmate (feature, default on, Keychain); agent (seams, marker, timings) | 2026-11-18 |
| D29 | One folder per profile (P10-PROFILE, headmate go 2026-11-18): `Application Support/nhetrinh/Default/` (no `NHT_PROFILE`) and `<name>/` (e.g. `readback/`), each with `session.json`, `prefs.json` and `profile.json` (`version`, `name`, `webStore`: `default` or the identifier, `keychainService`; a record: the app derives store and service from the name, never from the file). HARD RULE: `Default` keeps `WKWebsiteDataStore.default()` and P9's service `...signins.default`; another profile keeps P9's identifier store and `...signins.<name>`. Migration at launch, before any file is read: P9's root files (`session.json`, its bad and v1 files, `prefs.json`, its bad file, `running.marker`) into `Default/`, each one rename; a named profile's `profiles/<identifier>/` renamed `<name>/` by that profile's own launch (an identifier cannot be turned back into a name); a target that exists is kept and its source left (logged as a count); a failed move puts back that run's moves and the launch uses P9's folder; the next launch finishes what is left. The crash marker moves with the session, so a clean P9 quit stays clean. Refused names (`default` in any case, `profiles`, P9's file names, `/ : \`, a leading dot, edge spaces, control characters, over 64 characters): nothing kept, non-persistent store (NT-TAB-004). Settings Hub > Profile: Show data folder (Finder); Reset profile… (a sheet, Cancel default) empties the folder in use but `profile.json` and `running.marker`, deletes the profile's Keychain item and its store's website data, then one home tab; refused when the folder in use is not the profile's own (after a failed migration). Unit tests reach only a temporary root (`DataRoot`, guard test) | headmate (layout, hard rule); agent (rename per file, refused names, reset keeps, seams) | 2026-11-18 |
| D30 | History (P11-HISTORY, headmate request): the address bar suggests up to 8 visited pages and matching open tabs, with host prefix first, then frecency; records finished http/https main-frame pages in `history.sqlite` in the given folder, capped at 5,000; never sends typed text to a suggestion service. Return opens a row only after an arrow chooses it; otherwise it opens the typed text. Settings Hub > Remember history defaults on; off stops recording and shows open tabs only, while kept rows remain until Clear All. Clear Last Hour does not clear history. R54 is written and unit tested, not read back. Live dropdown behavior and the memory budget are not proven until the installed app is read back | headmate (feature); agent (interaction and retention details) | 2026-11-18 |

## Assumed, then accepted with the plan (D15)

Proposed by the agent; accepted as a group when the headmate approved the plan.

| Id | Assumption | If the headmate says no |
|---|---|---|
| A1 | Caps: `.md` 100 lines; `.swift` and other code 150 lines; function 30 lines; line 120 characters; 5 parameters | change the numbers in `_app/scripts/conventions/rules/sizes.py` (read by `conventions/_check.py`); nothing else moves |
| A2 | `rnd/` moves to `hubs/product/rnd/`, so `AGENTS.md` can sit at the root (5 root entries) | keep `rnd/` at the root and put the agent files only under `.claude/` |
| A3 | The readback tool drives the app through macOS Accessibility; this needs one permission grant for the terminal (since D23: R2 only) | weaker checks from inside the app, reported as such (risk R-1) |

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

Pinned tabs; a "copy URL" shortcut; a memory readout
per tab in the sidebar. None is built without a headmate request.
