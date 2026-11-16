# Triage — failures and tool gaps

One row per failure reason (`NT-<FAM>-*`) and tool gap (`NT-TG-*`). Bugs are in `../bugs/TRIAGE.md`.

| Id | Signature | Status | First check |
|---|---|---|---|
| NT-NAV-001 | `search cut off at &` | FIXED | `CharacterSet.urlQueryAllowed` keeps `& + = ? #` unescaped |
| NT-BLD-001 | `icon on a tile` | FIXED | macOS draws bundle `.icns` icons on a tile; runtime `applicationIconImage` is drawn as-is |
| NT-BLD-002 | `cp: .build/arm64-apple-macosx/release/Nhetrinh: No such file or directory` | FIXED | Script asks SwiftPM for the path (`--show-bin-path`), never hard-codes it |
| NT-GAT-001 | `error: plugin for module 'TestingMacros' not found` | FIXED | Was it plain `swift test`? Run `_app/scripts/test.sh`; compare `swift test -v` compile commands |
| NT-GAT-002 | `no testTarget depends on NhetrinhReadback` | FIXED | Does `_app/Package.swift` have `NhetrinhReadbackTests`? |
| NT-TAB-001 | `background tab stops playing after about 10 minutes` | OPEN | Does the idle unload ask WebKit for the media state first? Since P1-BUILD-1 it does (`IdleUnload.swift`); R11 PASS 22:09, red on P0 not run |
| NT-UIX-001 | `after New Tab the sidebar has 1 rows, not 2` | FIXED | Nil-target menu item and no key window (app not active)? Browser items target the controller |
| NT-UIX-002 | `the selected tab stays` | OBSERVED | Did a close of a row that is not selected select another tab? `close(at:)` selects only when the selected tab closes |
| NT-UIX-004 | `the sheet is still shown, the answer none` | OBSERVED | Tab closed or left with a page's sheet up? `endSheets(of:)` ends it unanswered |
| NT-NAV-002 | `link → "javascript:void(0)"` | OBSERVED | Is `javascript` in `ExternalScheme.staying`? It runs in its own page |
| NT-NAV-003 | `aSiteIsAnOrigin` | OBSERVED | Camera answer for another port or scheme? Keys are `SitePermissions.site(scheme:host:port:)` |
| NT-NAV-004 | `isMainFrame != false` | OBSERVED | A page asking to open another app in a loop? Ruling pending: ask only for a click |
| NT-TAB-002 | `ask selects the asking tab` | OBSERVED | A background tab pulling the user to it? Ruling pending: hold its question |
| NT-UIX-003 | `closingARowKeepsTheBackgroundSlotInPlace` | OBSERVED | A row above `backgroundSlot` closed? `close(at:)` must move the slot up by one |
| NT-ENV-001 | `whole machine at ~80% CPU during the bench` | OBSERVED | Does a scenario start many engine processes at once? Load one at a time |
| NT-ENV-002 | `memsum procs=1` for a WebKit app | FIXED | Was the app launched from a terminal? Launch via `open` |
| NT-ENV-003 | `first_load` 8-10 s for one run, under 1 s for the next | FIXED | Did the previous instance's helpers still run? Wait until all are gone |
| NT-ENV-004 | `no download row (downloads []`, `the app did not quit within 5 s` | FIXED | A download with the screen locked? `sample` the app: main thread in `_sandbox_extension_issue` means macOS asks for ~/Downloads; the first write must be off the main thread (`DownloadNamer.canWrite`) |
| NT-GAT-003 | `verdict: PASS (0 of 0)` | FIXED | Did a typo in `--steps` or a flag run every step? It must exit 2 with a usage error |
| NT-GAT-004 | `R2 ... PASS` with a tile as large as the Dock item | FIXED | Is the Dock colour read from a ring outside the item? Pale tile on a light Dock: known limit |
| NT-GAT-005 | `R2 FAIL` with two Dock items titled nhetrinh | FIXED | Is a copy of nhetrinh pinned in the Dock? R2 must take the running item of the launched bundle |
| NT-GAT-006 | `cannot set AXSelected (accessibility error -25202)` | FIXED | Did a step keep an element across a navigation? Look it up again right before acting |
| NT-GAT-007 | `R2 FAIL` with no tile seen, Dock on a side | FIXED | Is the Dock item wider than its icon? Score the icon's square; background per line along the Dock |
| NT-GAT-008 | `none has the role AXWindow`, `first roles [AXApplication, AXMenuBar]` | OPEN | Since D23 R1, R3-R7 read no AX window (probe); before: which roles did `AXWindows` give? Not the code (5f2592e..d76fce8 has no AX change); see NT-TG-003 |
| NT-GAT-009 | `exited with unexpected signal code 5` | OBSERVED | Does a `@MainActor` test run `RunLoop.main`? It runs other tests inside; press the item at once |
| NT-GAT-010 | `the confirm sheet's buttons are ["Cancel", "OK"]` | OBSERVED | A sheet's buttons from the probe are in view order: compare them as a set |
| NT-PRF-001 | `R8 ... app 60.0 MB (max 40)` | FIXED | `footprint -p`: a large `CG Image` row? The runtime Dock icon must be at most 256 px |
| NT-PRF-002 | `com.apple.WebKit.GPU above 40 MB` | OPEN | A 1-3 s GPU burst of ~100 MB? R8: median total of 9, a rise in the last 4, the highest app sample |
| NT-PRF-003 | `anIconOfHugePixelSizeIsRefusedBeforeItIsDecoded` | OBSERVED | A small icon file of huge pixel size? `Favicons.fits` reads the size before any decode |
| NT-PRF-004 | `aLargeDataHrefGivesNoIcon` | OBSERVED | A long `data:` icon href? It is a cache key: `FaviconURL` keeps 4 KB at most |
| NT-PRF-005 | `bundle 864 KB (max 1024)` | OBSERVED | Does the app export symbols (`nm -gU`)? `_build.sh` builds `-Osize -no_exported_symbols` and fails on any export; `make_icns.sh` checks the icon (`nearest.swift`) |
| NT-TG-001 | `cannot see the Dock` | OPEN | No safe way to read back the Dock icon (see the tool gap) |
| NT-TG-002 | `screenshot shows other windows` | OPEN | Capture one window by id, never a screen region |
| NT-TG-003 | `has no Accessibility permission`, `Accessibility reads are empty`, `its tree was not read` | OPEN | R1, R3-R7: `answers no readback probe`? Is the installed app built before D23? Install it. R2: which app does the reason name? Run as the granted app: `readback_app.sh run`; after a rebuild grant again (R-2); reads empty with the grant kept (19:51): re-grant, cause not proven |
| NT-TG-004 | `end: the app still runs`, a nhetrinh with `NHT_PROFILE=readback` after the run | OPEN | Read the report's `end:` line; `pgrep -fl 'Applications/nhetrinh.app'`; end only a `readback` profile instance, by pid |
| NT-TG-005 | `Cannot request fullscreen in a hidden document`, `media: asking (hidden)` | OPEN | R26a, R26b NOT READ BACK: the app runs without the focus (D18), WebKit counts the page as hidden; run with `--allow-focus` (D25) |
| NT-TG-006 | `file choice: unit test only` | OPEN | R22: panel and Cancel read back; the file choice is `UploadTests` (ruling, as R17) |
