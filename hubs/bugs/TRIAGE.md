# Triage — bugs

One row per bug (`NT-BUG-*`); failure reasons and tool gaps are in `../failures/TRIAGE.md`.
Grep the signature in the report or log.

| Id | Signature | Status | First check |
|---|---|---|---|
| NT-BUG-001 | `search cut off at &` | FIXED | Query value escapes `& + = ? #`, not just `urlQueryAllowed` (NT-NAV-001) |
| NT-BUG-002 | `Dock icon on a black tile` | FIXED | Icon set at runtime via `applicationIconImage`, not only the `.icns` (NT-BLD-001) |
| NT-BUG-003 | `after New Tab the sidebar has 1 rows, not 2` | FIXED | Does the menu item have a target? With no key window a nil target reaches nobody (NT-UIX-001) |
| NT-BUG-004 | `the selected tab stays` | OBSERVED | Closing a row that is not selected must keep the selection (NT-UIX-002) |
| NT-BUG-005 | `closingARowKeepsTheBackgroundSlotInPlace` | OBSERVED | Did a row above the background slot close? `close(at:)` must move the slot (NT-UIX-003) |
| NT-BUG-006 | `the sheet is still shown, the answer none` | OBSERVED | Was the tab closed or left with its sheet up? `endSheets(of:)` (NT-UIX-004) |
| NT-BUG-007 | `aCapturingTabIsKept` | OBSERVED | A call in a background tab is unloaded: see the fix entry (P4P6-FIX-1) |
| NT-BUG-008 | `aBooleanIsNotMinutes` | OBSERVED | The settings file is read wrongly: see the fix entry (P4P6-FIX-1) |
| NT-BUG-009 | `anAnswerIsNotCarriedToAnotherTab` | OBSERVED | The find answer is shown on another tab: see the fix entry (P4P6-FIX-1) |
| NT-BUG-010 | `clearAllForgetsTheZoom` | OBSERVED | Clear All keeps the zoomed sites: see the fix entry (P4P6-FIX-1) |
| NT-BUG-011 | `zoomReachesEveryLoadedTabOfTheHost` | OBSERVED | The zoom stays on one tab of a site: see the fix entry (P4P6-FIX-1) |
| NT-BUG-012 | `zoomInHasBothKeys` | OBSERVED | Command-equals does not zoom in: see the fix entry (P4P6-FIX-1) |
| NT-BUG-013 | `reopenPutsTheTabBackWhereItWas` | OBSERVED | Did the closed tab keep its path and folder name? `ClosedTab.path`, `Tree.reinsert` |
| NT-BUG-014 | `closingTheSelectedTabSelectsAVisibleTab` | OBSERVED | Is the chosen tab in a collapsed folder? `close(at:)` must use `Tree.nearestVisible` |
| NT-BUG-015 | `foldersWithoutATabAreKept` | OBSERVED | A session of folders and no tab: `TreeSession.withHomeTab` keeps them |
| NT-BUG-016 | `moveTabStepsOneRow` | OBSERVED | Did Move use the flat index? It must be `Tree.step` on the path |
| NT-BUG-017 | `aCancelNeverRemovesTheNextDownloadsFile` | OBSERVED | A finished download gone after a cancel of the same name? The name is free only after WebKit confirms the cancel (NT-NAV-005) |
| NT-BUG-018 | `theLeftButtonsClearTheTrafficLights` | OBSERVED | Sidebar hidden and the toolbar's buttons under the traffic lights? `placeRow` must read the real zoom button (NT-UIX-005) |
