# M1 — Daily driver (P0, P1, P2)

After M1 the headmate can use nhetrinh every day: tabs survive a restart, the sidebar behaves
like a real one, and background music is not cut. The gate is in `_PLAN.md`.

## P0 — Foundation (0.1.0, size L, status TODO)

Goal: every later phase is built, checked and read back in the same way.

Build:
1. `check_conventions.py` replaces `check_tree.py`. It checks: one `_` entry per folder, 5 entries
   per folder, `.md` 100 lines, `.swift` / `.py` / `.c` / `.sh` 150 lines, function 30 lines,
   line 120 characters, 5 parameters, no package dependencies. It has its own tests: one broken
   tree per rule.
2. Fix today's violations: split `_BrowserWindowController.swift` (209 lines) into `_Window/`
   (controller and its extensions) and `Tab/`; split `_bench.py` (186 lines).
3. Harness: `AGENTS.md` at the root, `.claude/CLAUDE.md`, and skills `nhetrinh-develop`,
   `nhetrinh-readback`, `nhetrinh-hubs`, `nhetrinh-ship` (each 100 lines or less).
   `rnd/` moves to `hubs/product/rnd/` to free the root slot (`DECISIONS.md` A2).
4. Readback tool: target `NhetrinhReadback`, run with `swift run nhetrinh-readback`. It starts
   the installed app the way the Dock does and drives it through the macOS Accessibility API:
   real clicks and real keys. The views get accessibility identifiers. It writes a verdict file
   (one PASS / FAIL line per step) and its path goes to `hubs/failures/evidence/_INDEX.md`.
5. Safe benchmark: `_bench.py` loads tabs one at a time, 10 at most. The 30-tab scenario is removed.
6. Code hygiene from the conventions: `os.Logger` on every failure path, no force unwraps.

Readback steps (the base set, run again in every later phase):
- R1 the window opens with the sidebar and the address bar.
- R2 the Dock icon has no tile. Only the Dock item's own rectangle is captured.
- R3 type `example.com`, Return: the title is "Example Domain".
- R4 type `rock & roll`, Return: the URL holds `q=rock%20%26%20roll`.
- R5 ⌘T, then ⌘W: sidebar rows +1, then -1.
- R6 click another sidebar row: the page changes.
- R7 start with 3 tabs: 1 page process runs.
- R8 the lightness budget.

Exit: checker 0 violations; `swift test` green; R1-R8 PASS on `~/Applications/nhetrinh.app`;
CI green; NT-BUG-001, NT-BUG-002, NT-ENV-001, NT-BLD-002 are FIXED with proof; NT-TG-001 and
NT-TG-002 are closed by the tool.

Needs from the headmate: Accessibility permission for the terminal, one time.

## P1 — Tab lifecycle: session restore and safe unload (0.2.0, size M, status TODO)

Goal: quit and open again without losing tabs. An idle tab is never unloaded while it plays.

Build, Core:
- `Session`: version, tabs (URL and title), selected index, sidebar width, collapsed.
- `SessionStore`: atomic write to `~/Library/Application Support/nhetrinh/session.json`.
  A corrupt file, or one from a newer version, is kept as `session.bad.json` and the app starts
  with one home tab: no crash and no silent loss.
- `UnloadPolicy.tabsToUnload`: a pure function of idle time, selected tab and "is playing".

Build, App:
- Save 2 seconds after any tab change, and at quit. At launch every tab is restored unloaded;
  only the selected tab loads.
- Before an unload, ask WebKit for the media state (`requestMediaPlaybackState`). A playing tab
  is kept (NT-TAB-001).
- At unload keep the tab's `interactionState`; at reload give it back, so back / forward history
  and scroll position return. Not proven yet: that this holds after the web view is destroyed.
  If it does not: fall back to the URL and the scroll offset.

Tests: session round trip; corrupt JSON; unknown version; empty session gives a home tab;
100 tabs; the `UnloadPolicy` table (idle time x selected x playing).

Readback adds:
- R9 open 3 tabs, select the 2nd, ⌘Q, launch: the same 3 rows, the 2nd selected, 1 page process.
- R10 kill the app (signal 9), launch: the state of the last save is back.
- R11 a background tab plays audio past the idle limit (limit set to 5 s for the run): it stays
  loaded. A silent tab in the same run is unloaded.
- R12 click an unloaded tab: the same URL loads and ⌘[ goes back in its history.

Exit: the gate, R1-R12 PASS.

## P2 — Sidebar and tab handling (0.3.0, size M, status TODO)

Goal: the sidebar feels finished.

Build:
- Row: favicon (16 pt), title, close button on hover. Middle-click closes.
- Drag a row to reorder. ⌃Tab and ⌃⇧Tab: next and previous tab.
- ⌘⇧T reopens the last closed tab (Core `ClosedTabs`: the last 20, this run only).
- ⌘-click a link: a new tab in the background.
- Toolbar: reload becomes stop while a page loads; a thin progress line under the toolbar.
- Favicons: the page's `<link rel="icon">`, else `/favicon.ico`; a memory cache of 200 icons at most.

Tests: `ClosedTabs` (push, pop, cap); `TabOrder.move(from:to:)` index math; favicon URL
resolution (relative, absolute, missing).

Readback adds:
- R13 hover a row: a close button appears; press it: rows -1.
- R14 drag row 3 above row 1: the new order shows, and stays after a relaunch.
- R15 ⌘⇧T: the row is back with the same URL.
- R16 a site that has an icon shows it in its row.
- R17 ⌘-click a link on a local test page: rows +1, the selected tab does not change.
- R18 stop a slow local page: loading ends and the button is reload again.

Exit: the gate, R1-R18 PASS; favicons add 2 MB or less to the app process.
