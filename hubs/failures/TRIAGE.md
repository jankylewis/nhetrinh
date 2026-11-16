# Triage — failures and tool gaps

One row per failure reason (`NT-<FAM>-*`) and tool gap (`NT-TG-*`). Bugs are in `../bugs/TRIAGE.md`.

| Id | Signature | Status | First check |
|---|---|---|---|
| NT-NAV-001 | `search cut off at &` | OBSERVED | `CharacterSet.urlQueryAllowed` keeps `& + = ? #` unescaped |
| NT-BLD-001 | `icon on a tile` | OBSERVED | macOS draws bundle `.icns` icons on a tile; runtime `applicationIconImage` is drawn as-is |
| NT-BLD-002 | `cp: .build/arm64-apple-macosx/release/Nhetrinh: No such file or directory` | OBSERVED | Script asks SwiftPM for the path (`--show-bin-path`), never hard-codes it |
| NT-GAT-001 | `error: plugin for module 'TestingMacros' not found` | OBSERVED | Was it plain `swift test`? Run `_app/scripts/test.sh`; compare `swift test -v` compile commands |
| NT-GAT-002 | `no testTarget depends on NhetrinhReadback` | OBSERVED | Does `_app/Package.swift` have `NhetrinhReadbackTests`? |
| NT-TAB-001 | `background tab stops playing after about 10 minutes` | OPEN | Does the idle unload ask WebKit for the media state first? (not seen live yet) |
| NT-ENV-001 | `whole machine at ~80% CPU during the bench` | OBSERVED | Does a scenario start many engine processes at once? Load one at a time |
| NT-ENV-002 | `memsum procs=1` for a WebKit app | FIXED | Was the app launched from a terminal? Launch via `open` |
| NT-ENV-003 | `first_load` 8-10 s for one run, under 1 s for the next | FIXED | Did the previous instance's helpers still run? Wait until all are gone |
| NT-GAT-003 | `verdict: PASS (0 of 0)` | OBSERVED | Did a typo in `--steps` or a flag run every step? It must exit 2 with a usage error |
| NT-GAT-004 | `R2 ... PASS` with a tile as large as the Dock item | OBSERVED | Is the Dock colour read from a ring outside the item? Pale tile on a light Dock: known limit |
| NT-PRF-001 | `R8 ... app 60.0 MB (max 40)` | OBSERVED | `footprint -p`: a large `CG Image` row? The runtime Dock icon must be at most 256 px |
| NT-PRF-002 | `com.apple.WebKit.GPU above 40 MB` | OPEN | A 1-3 s GPU burst of ~100 MB? R8: median total of 9, a rise in the last 4, the highest app sample |
| NT-TG-001 | `cannot see the Dock` | OPEN | No safe way to read back the Dock icon (see the tool gap) |
| NT-TG-002 | `screenshot shows other windows` | OPEN | Capture one window by id, never a screen region |
| NT-TG-003 | `AXIsProcessTrusted` false in an agent session | OPEN | Run the readback as its own granted app: `_app/scripts/install/readback_app.sh run` |
