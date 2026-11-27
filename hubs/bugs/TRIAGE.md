# Triage — bugs

One row per bug (`NT-BUG-*`); failure reasons and tool gaps are in `../failures/TRIAGE.md`.
Grep the signature in the report or log.

| Id | Found by | Signature | Status | First check |
|---|---|---|---|---|
| NT-BUG-001 | development | `search cut off at &` | FIXED | Query value escapes `& + = ? #`, not just `urlQueryAllowed` (NT-NAV-001) |
| NT-BUG-002 | headmate | `Dock icon on a black tile` | FIXED | Icon set at runtime via `applicationIconImage`, not only the `.icns` (NT-BLD-001) |
| NT-BUG-003 | readback | `after New Tab the sidebar has 1 rows, not 2` | FIXED | Does the menu item have a target? With no key window a nil target reaches nobody (NT-UIX-001) |
| NT-BUG-004 | development | `the selected tab stays` | OBSERVED | Closing a row that is not selected must keep the selection (NT-UIX-002) |
| NT-BUG-005 | development | `closingARowKeepsTheBackgroundSlotInPlace` | OBSERVED | Did a row above the background slot close? `close(at:)` must move the slot (NT-UIX-003) |
| NT-BUG-006 | development | `the sheet is still shown, the answer none` | OBSERVED | Was the tab closed or left with its sheet up? `endSheets(of:)` (NT-UIX-004) |
| NT-BUG-007 | development | `aCapturingTabIsKept` | OBSERVED | A call in a background tab is unloaded: see the fix entry (P4P6-FIX-1) |
| NT-BUG-008 | development | `aBooleanIsNotMinutes` | OBSERVED | The settings file is read wrongly: see the fix entry (P4P6-FIX-1) |
| NT-BUG-009 | development | `anAnswerIsNotCarriedToAnotherTab` | OBSERVED | The find answer is shown on another tab: see the fix entry (P4P6-FIX-1) |
| NT-BUG-010 | development | `clearAllForgetsTheZoom` | OBSERVED | Clear All keeps the zoomed sites: see the fix entry (P4P6-FIX-1) |
| NT-BUG-011 | development | `zoomReachesEveryLoadedTabOfTheHost` | OBSERVED | The zoom stays on one tab of a site: see the fix entry (P4P6-FIX-1) |
| NT-BUG-012 | development | `zoomInHasBothKeys` | OBSERVED | Command-equals does not zoom in: see the fix entry (P4P6-FIX-1) |
| NT-BUG-013 | development | `reopenPutsTheTabBackWhereItWas` | OBSERVED | Did the closed tab keep its path and folder name? `ClosedTab.path`, `Tree.reinsert` |
| NT-BUG-014 | development | `closingTheSelectedTabSelectsAVisibleTab` | OBSERVED | Is the chosen tab in a collapsed folder? `close(at:)` must use `Tree.nearestVisible` |
| NT-BUG-015 | development | `foldersWithoutATabAreKept` | OBSERVED | A session of folders and no tab: `TreeSession.withHomeTab` keeps them |
| NT-BUG-016 | development | `moveTabStepsOneRow` | OBSERVED | Did Move use the flat index? It must be `Tree.step` on the path |
| NT-BUG-017 | development | `aCancelNeverRemovesTheNextDownloadsFile` | OBSERVED | A finished download gone after a cancel of the same name? The name is free only after WebKit confirms the cancel (NT-NAV-005) |
| NT-BUG-018 | headmate | `theLeftButtonsClearTheTrafficLights` | OBSERVED | Sidebar hidden and the toolbar's buttons under the traffic lights? `placeRow` must read the real zoom button (NT-UIX-005) |
| NT-BUG-019 | headmate | `NSURLErrorDomain -1022` | OBSERVED | Plain http fails but not on localhost? Does the built Info.plist have `NSAllowsArbitraryLoadsInWebContent` (NT-BLD-005) |
| NT-BUG-020 | headmate | `sign-ins: restored 0` | OBSERVED | Signed out after a relaunch? Was the quit clean (no `running.marker`) and Remember sign-ins on? (after a reinstall: was the build signed with the local identity? NT-BLD-006) |
| NT-BUG-021 | headmate | `typing https shows nothing` | OBSERVED | Does the address field show visited pages and open tabs below it while typing? P11-HISTORY; R54 not read back |
| NT-BUG-022 | headmate | `dark dropdown, black text` | FIXED | Text unreadable on a coloured surface? A layer colour set outside drawing must resolve in the view's `effectiveAppearance` |
| NT-BUG-023 | headmate | `address field gone, ⌘L does nothing` | FIXED | Toolbar without the address field? Is the row's layout ambiguous (`hasAmbiguousLayout`)? (NT-UIX-006) |
| NT-BUG-024 | headmate | `can scroll horizontally, cannot scroll vertically` | NOT_A_BUG | Withdrawn by the headmate. Does the same page scroll in another browser? An inner scroll area or modal may hold the scroll |
| NT-BUG-026 | headmate | `not in the default web browser list` | FIXED | Does Info.plist claim what browsers claim: http, https, file, public.html, Handoff? (`browser_claims` in `_build.sh`) |
| NT-BUG-027 | self-test | `aLocalPageReadsAndOpensItsParentsFiles` | FIXED | Does a local page get read access above its own folder? (`IncomingLink.readAccess`) |
| NT-BUG-028 | self-test | `aRestingLocalPageComesBackWithItsHistory` | FIXED | Does `load` restore `interactionState` for a `file:` tab too? |
| NT-BUG-029 | readback | `the dropdown's first row is "<url> — <url>"` | FIXED | Is the history row's title empty? `didFinish` came before the title: does the title observer call `retitleVisit`? |
| NT-BUG-030 | headmate | `the address bar shows a long address on two lines` | OPEN | Does `ToolbarView.address` wrap? (`cell.wraps`, `usesSingleLineMode`, `lineBreakMode`) |
| NT-BUG-031 | headmate | `Open With on a .pdf does not list nhetrinh` | OPEN | Does Info.plist claim `com.adobe.pdf` (`CFBundleDocumentTypes`, `browser_claims` in `_build.sh`)? |
| NT-BUG-032 | headmate | `a click on the user's picture shows nothing` | NOT_A_BUG | Console errors on the click? Does Safari open it? A frame asking for storage access? |
