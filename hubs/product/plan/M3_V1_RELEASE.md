# M3 — Version 1.0 (P6, P7, P8)

After M3 nhetrinh stays light under memory pressure, has tab folders, and has a released
build that anyone can download. The gate is in `_PLAN.md`.

## P6 — Memory guard (0.7.0, size S, status DOING)

Goal: when macOS is short of memory, nhetrinh gives memory back at once.

Build:
- Listen to macOS memory pressure (`DispatchSource.makeMemoryPressureSource`).
- `UnloadPolicy` gets a pressure input. Normal: background tabs idle longer than N minutes.
  Warning: background tabs idle longer than 1 minute. Critical: all background tabs.
  A playing tab is still kept at every level.
- Trim our own process: no web view is held for an unloaded tab; the favicon cache is emptied
  at the critical level.
- A readback-only trigger: when the app runs with `NHT_READBACK=1` it accepts a "simulate
  pressure" call. Real system pressure is never made on the headmate's machine.
- One more budget row: 3 tabs opened and 2 of them unloaded cost the one-tab budget + 15 MB.

Tests: the `UnloadPolicy` table grows by the pressure level.

Readback adds:
- R36 3 loaded tabs, simulate a warning: 1 page process is left. Click an unloaded tab: it
  loads again with its history.
- R37 a playing tab is still loaded after a warning; a critical level then unloads a fresh silent
  background tab (the control) and keeps the playing one (NT-GAT-011).
- R38 the budget with 2 unloaded tabs. It loads example.com, .org and .net: like R8 it needs the
  Internet, and a slow network can fail it (P4/P6 review, F11).

Exit: the gate, R1-R38 PASS.

## P7 — Tab folders (0.8.0, size L, status DOING)

Goal: collapsible groups in the sidebar, as in the headmate's reference screenshot.

Build, Core:
- `TabTree`: ordered items, each one a tab or a folder (name, collapsed, tabs). One level
  only: no folder inside a folder.
- Operations: add folder, rename, move a tab (into, out of, inside), collapse, delete folder.
  Deleting a folder moves its tabs to the root. It never closes them.
- Session schema version 2, with a migration from version 1 (flat list to root tabs).
  The version 1 file is kept once as a backup.

Build, App:
- The sidebar becomes an outline view. Drag a tab onto a folder; drag folders to reorder.
- Context menu: New Folder, Rename, Delete Folder.
- A collapsed folder that holds the selected tab is marked.
- ⌘1 to ⌘9 count the visible tabs from the top.

Tests: every `TabTree` operation, parameterized; migration 1 to 2 with fixture files;
version 2 round trip; "delete folder keeps its tabs".
Red first (P7-PREP-1, D24): stubs in `NhetrinhCore/Tabs/Lifecycle/Tree/`, 21 tests (58 cases) in
`Tests/_NhetrinhCoreTests/Tabs/Lifecycle/Tree/`; the version 2 file shape is fixed by `SessionFixtures.swift`.
P7-BUILD-1: `Session` stays the version 1 model, read only to migrate; `TreeSession` is version 2 (folding
them would rewrite P1's session tests for no change in the file).

Readback adds:
- R39 New Folder, name "work": the row appears.
- R40 drag 2 tabs in: the folder holds 2.
- R41 collapse: 2 rows hide. Relaunch: folder, name, members and collapsed state are kept.
- R42 delete the folder: the 2 tabs are back at the root.
- R43 start with a version 1 session fixture: every tab is present.

Exit: the gate, R1-R43 PASS.

Rulings after the P7 review (P7-FIX-1, NT-BUG-013 to 016): Reopen Closed Tab goes back into its folder
(by name; a deleted folder: the root at its place); closing the selected tab selects the nearest visible
tab; folders with no tab come back with one home tab; Move Tab Up / Down step one row in the container.
Notes: R41 collapses by the row menu only (the disclosure triangle and the outline's own selection change
are not read back; a drag is unit-tested only). A build before P7 reads a version 2 file as newer and
keeps it as `session.bad.json` (no downgrade is planned).

Note: this is the largest phase. It can move after 1.0 without blocking it (`DECISIONS.md` Q2).

## P8 — Release 1.0 (1.0.0, size S, status TODO)

Goal: anyone can download and run nhetrinh. The headmate's installed app is the released build.

Build:
- `release.yml`: on a tag `v*` run the checker, the tests and the build; zip the app; compute
  the SHA-256; make a GitHub Release. The notes are built from the `product/features` rows.
- README: install, shortcuts, known limits, and how to open an app that is not notarized.
- Apple silicon only (the smallest app). An Intel build only when asked.
- Not notarized: there is no Apple Developer ID. The first open of a downloaded copy shows the
  macOS warning. If the headmate gets an ID later, notarization is added as a new phase.
- Final lightness report: the budget table against the measured numbers and the R&D baseline.

Readback adds:
- R44 download the zip from the Release page, check the SHA-256, unzip to a temporary folder,
  launch: R1-R8 PASS on that copy.
- R45 the full run R1-R43 on the installed 1.0.0.

Exit: every R step PASS; every hub item is FIXED or listed in the README as a known limit;
CI and the release run are green.

## After 1.0

A feature is added only when the headmate asks. Each request becomes a new phase in this plan,
with the same gate, its own readback steps and its budget check.
