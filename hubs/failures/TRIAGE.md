# Triage — failures and tool gaps

One row per failure reason (`NT-<FAM>-*`) and tool gap (`NT-TG-*`). Bugs are in `../bugs/TRIAGE.md`.

| Id | Signature | Status | First check |
|---|---|---|---|
| NT-NAV-001 | `search cut off at &` | OBSERVED | `CharacterSet.urlQueryAllowed` keeps `& + = ? #` unescaped |
| NT-BLD-001 | `icon on a tile` | OBSERVED | macOS draws bundle `.icns` icons on a tile; runtime `applicationIconImage` is drawn as-is |
| NT-BLD-002 | `cp: .build/arm64-apple-macosx/release/Nhetrinh: No such file or directory` | OBSERVED | Script asks SwiftPM for the path (`--show-bin-path`), never hard-codes it |
| NT-TAB-001 | `background tab stops playing after about 10 minutes` | OPEN | Does the idle unload ask WebKit for the media state first? (not seen live yet) |
| NT-ENV-001 | `whole machine at ~80% CPU during the bench` | OBSERVED | Does a scenario start many engine processes at once? Load one at a time |
| NT-ENV-002 | `memsum procs=1` for a WebKit app | FIXED | Was the app launched from a terminal? Launch via `open` |
| NT-ENV-003 | `first_load` 8-10 s for one run, under 1 s for the next | FIXED | Did the previous instance's helpers still run? Wait until all are gone |
| NT-PRF-001 | `R8 ... app 60.0 MB (max 40)` | OBSERVED | `footprint -p`: a large `CG Image` row? The runtime Dock icon must be at most 256 px |
| NT-PRF-002 | `com.apple.WebKit.GPU above 40 MB` | OPEN | Did the GPU helper spike in this run only? Measure again before blaming the app |
| NT-TG-001 | `cannot see the Dock` | OPEN | No safe way to read back the Dock icon (see the tool gap) |
| NT-TG-002 | `screenshot shows other windows` | OPEN | Capture one window by id, never a screen region |
