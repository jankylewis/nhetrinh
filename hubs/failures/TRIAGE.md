# Triage — failures and tool gaps

One row per failure reason (`NT-<FAM>-*`) and tool gap (`NT-TG-*`). Bugs are in `../bugs/TRIAGE.md`.

| Id | Found by | Signature | Status | First check |
|---|---|---|---|---|
| NT-NAV-001 | development | `search cut off at &` | FIXED | `CharacterSet.urlQueryAllowed` keeps `& + = ? #` unescaped |
| NT-BLD-001 | headmate | `icon on a tile` | FIXED | macOS draws bundle `.icns` icons on a tile; runtime `applicationIconImage` is drawn as-is |
| NT-BLD-002 | self-test | `cp: .build/arm64-apple-macosx/release/Nhetrinh: No such file or directory` | FIXED | Script asks SwiftPM for the path (`--show-bin-path`), never hard-codes it |
| NT-BLD-003 | development | `test_the_real_notes_do_not_contradict_themselves` | OBSERVED | Old or internal words in the notes? Edit the Release note column of the older rows (`-` leaves a row out) |
| NT-BLD-004 | development | `test_a_feature_row_of_the_wrong_shape_is_an_error` | OBSERVED | A feature row with a missing column? `release_notes.py` must stop with its line number |
| NT-GAT-001 | self-test | `error: plugin for module 'TestingMacros' not found` | FIXED | Was it plain `swift test`? Run `_app/scripts/test.sh`; compare `swift test -v` compile commands |
| NT-GAT-002 | development | `no testTarget depends on NhetrinhReadback` | FIXED | Does `_app/Package.swift` have `NhetrinhReadbackTests`? |
| NT-TAB-001 | development | `background tab stops playing after about 10 minutes` | OPEN | Does the idle unload ask WebKit for the media state first? Since P1-BUILD-1 it does (`IdleUnload.swift`); R11 PASS 22:09, red on P0 not run |
| NT-UIX-001 | readback | `after New Tab the sidebar has 1 rows, not 2` | FIXED | Nil-target menu item and no key window (app not active)? Browser items target the controller |
| NT-UIX-002 | development | `the selected tab stays` | OBSERVED | Did a close of a row that is not selected select another tab? `close(at:)` selects only when the selected tab closes |
| NT-UIX-004 | development | `the sheet is still shown, the answer none` | OBSERVED | Tab closed or left with a page's sheet up? `endSheets(of:)` ends it unanswered |
| NT-NAV-002 | self-test | `link → "javascript:void(0)"` | OBSERVED | Is `javascript` in `ExternalScheme.staying`? It runs in its own page |
| NT-NAV-003 | development | `aSiteIsAnOrigin` | OBSERVED | Camera answer for another port or scheme? Keys are `SitePermissions.site(scheme:host:port:)` |
| NT-NAV-004 | development | `isMainFrame != false` | OBSERVED | A page asking to open another app in a loop? Ruling pending: ask only for a click |
| NT-TAB-002 | development | `ask selects the asking tab` | OBSERVED | A background tab pulling the user to it? Ruling pending: hold its question |
| NT-TAB-003 | self-test | `aLinkFromAnotherAppKeepsTheFolders` | OBSERVED | Folders gone after a new tab? A mutation of the flat `tabs` rebuilds the tree: insert through `tree` |
| NT-UIX-003 | development | `closingARowKeepsTheBackgroundSlotInPlace` | OBSERVED | A row above `backgroundSlot` closed? `close(at:)` must move the slot up by one |
| NT-UIX-005 | headmate | `theLeftButtonsClearTheTrafficLights` | OBSERVED | A toolbar control at a fixed x under the title bar? Place it from `standardWindowButton(.zoomButton)`'s frame, on every layout |
| NT-ENV-001 | headmate | `whole machine at ~80% CPU during the bench` | OBSERVED | Does a scenario start many engine processes at once? Load one at a time |
| NT-ENV-002 | development | `memsum procs=1` for a WebKit app | FIXED | Was the app launched from a terminal? Launch via `open` |
| NT-ENV-003 | development | `first_load` 8-10 s for one run, under 1 s for the next | FIXED | Did the previous instance's helpers still run? Wait until all are gone |
| NT-ENV-004 | readback | `no download row (downloads []`, `the app did not quit within 5 s` | FIXED | A download with the screen locked? `sample` the app: main thread in `_sandbox_extension_issue` means macOS asks for ~/Downloads; the first write must be off the main thread (`DownloadNamer.canWrite`) |
| NT-GAT-003 | development | `verdict: PASS (0 of 0)` | FIXED | Did a typo in `--steps` or a flag run every step? It must exit 2 with a usage error |
| NT-GAT-004 | development | `R2 ... PASS` with a tile as large as the Dock item | FIXED | Is the Dock colour read from a ring outside the item? Pale tile on a light Dock: known limit |
| NT-GAT-005 | readback | `R2 FAIL` with two Dock items titled nhetrinh | FIXED | Is a copy of nhetrinh pinned in the Dock? R2 must take the running item of the launched bundle |
| NT-GAT-006 | readback | `cannot set AXSelected (accessibility error -25202)` | FIXED | Did a step keep an element across a navigation? Look it up again right before acting |
| NT-GAT-007 | readback | `R2 FAIL` with no tile seen, Dock on a side | FIXED | Is the Dock item wider than its icon? Score the icon's square; background per line along the Dock |
| NT-GAT-008 | readback | `none has the role AXWindow`, `first roles [AXApplication, AXMenuBar]` | OPEN | Since D23 R1, R3-R7 read no AX window (probe); before: which roles did `AXWindows` give? Not the code (5f2592e..d76fce8 has no AX change); see NT-TG-003 |
| NT-GAT-009 | self-test | `exited with unexpected signal code 5` | OBSERVED | Does a `@MainActor` test run `RunLoop.main`? It runs other tests inside; press the item at once |
| NT-GAT-010 | readback | `the confirm sheet's buttons are ["Cancel", "OK"]` | OBSERVED | A sheet's buttons from the probe are in view order: compare them as a set |
| NT-GAT-011 | development | `R37 PASS` with no tab left for the critical level | FIXED | Would the check fail if the action did nothing, or the other button? Add a control the action must change (R37 row 4, `ClearRange`, R29 relaunch) |
| NT-GAT-012 | headmate | `noTestWindowIsEverVisible` | OBSERVED | A window on screen during test.sh? Does a sheet or window skip `Screen.presenter`? |
| NT-GAT-013 | self-test | `aDownloadIsPartialUntilDoneThenQuarantined` | OBSERVED | A wait on a clock, or two reads of one folder? Wait for the event (the row's rename), read once |
| NT-GAT-014 | readback | `the save at quit is not version 2` | OBSERVED | Does a step pin a number the app writes? Read it from the app's constant (`TreeSession.version`) |
| NT-GAT-015 | readback | `R2 FAIL` agreement 90 % (13:19), 80 % (13:57), build c751b08 | OBSERVED | Neighbours in the ring on a 20 pt Dock? R2 now reads only the item's own frame; the FAIL line names item and capture |
| NT-PRF-001 | readback | `R8 ... app 60.0 MB (max 40)` | FIXED | `footprint -p`: a large `CG Image` row? The runtime Dock icon must be at most 256 px |
| NT-PRF-002 | development | `com.apple.WebKit.GPU above 40 MB` | OPEN | A 1-3 s GPU burst of ~100 MB? R8: median total of 9, a rise in the last 4, the highest app sample |
| NT-PRF-003 | development | `anIconOfHugePixelSizeIsRefusedBeforeItIsDecoded` | OBSERVED | A small icon file of huge pixel size? `Favicons.fits` reads the size before any decode |
| NT-PRF-004 | development | `aLargeDataHrefGivesNoIcon` | OBSERVED | A long `data:` icon href? It is a cache key: `FaviconURL` keeps 4 KB at most |
| NT-PRF-005 | readback | `bundle 864 KB (max 1024)` | OBSERVED | Does the app export symbols (`nm -gU`)? `_build.sh` builds `-Osize -no_exported_symbols` and fails on any export; `make_icns.sh` checks the icon (`nearest.swift`) |
| NT-TG-001 | development | `cannot see the Dock` | OPEN | No safe way to read back the Dock icon (see the tool gap) |
| NT-TG-002 | development | `screenshot shows other windows` | OPEN | Capture one window by id, never a screen region |
| NT-TG-003 | readback | `has no Accessibility permission`, `Accessibility reads are empty`, `its tree was not read` | OPEN | R1, R3-R7: `answers no readback probe`? Is the installed app built before D23? Install it. R2: which app does the reason name? Run as the granted app: `readback_app.sh run`; after a rebuild grant again (R-2); reads empty with the grant kept (19:51): re-grant, cause not proven |
| NT-TG-004 | readback | `end: the app still runs`, a nhetrinh with `NHT_PROFILE=readback` after the run | OPEN | Read the report's `end:` line; `pgrep -fl 'Applications/nhetrinh.app'`; end only a `readback` profile instance, by pid |
| NT-TG-005 | readback | `Cannot request fullscreen in a hidden document`, `media: asking (hidden)` | OPEN | R26a, R26b NOT READ BACK: the app runs without the focus (D18), WebKit counts the page as hidden; run with `--allow-focus` (D25) |
| NT-TG-006 | development | `file choice: unit test only` | OPEN | R22: panel and Cancel read back; the file choice is `UploadTests` (ruling, as R17) |
| NT-NAV-005 | development | `aCancelNeverRemovesTheNextDownloadsFile` | OBSERVED | A cancel deletes the next download's file? P5-FIX-1 (p5/review) |
| NT-NAV-006 | development | `everyRunningDownloadCanBeCancelled` | OBSERVED | Running downloads hidden, a page downloads without asking? P5-FIX-1 (p5/review) |
| NT-NAV-007 | development | `linksFromAnotherAppLoadOnlyTheShownTab` | OBSERVED | Links from another app load every tab? P5-FIX-1 (p5/review) |
| NT-NAV-008 | development | `cleanRemovesLineBreakingSeparators` | OBSERVED | A line separator kept in a file name? P5-FIX-1 (p5/review) |
| NT-NAV-009 | development | `aDownloadIsPartialUntilDoneThenQuarantined` | OBSERVED | A download quarantined as sandboxed, not as a web download? P5-FIX-1 (p5/review) |
| NT-NAV-010 | development | `race.txt.download` | OBSERVED | A partial download under its final name? P5-FIX-1 (p5/review) |
| NT-NAV-011 | development | `isRunning(entry)` | OBSERVED | A cancel while the name is chosen? P5-FIX-1 (p5/review) |
| NT-NAV-012 | development | `sameFileIgnoresCaseAndNormalization` | OBSERVED | Two spellings of one name? P5-FIX-1 (p5/review) |
| NT-NAV-013 | readback | `aDownloadSaysWhereItCameFrom` | OBSERVED | Finder's "Where from" blank? Is `com.apple.metadata:kMDItemWhereFroms` on the file? The quarantine drops its URLs on this macOS (P5-FIX-2) |
| NT-BLD-005 | headmate | `NSURLErrorDomain -1022` | OBSERVED | No `NSAppTransportSecurity` in the built Info.plist? ATS refuses plain http but localhost and IP addresses (unqualified and `.local` names too: recalled, not proven) |
