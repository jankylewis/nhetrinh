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
| NT-TG-001 | `cannot see the Dock` | OPEN | No safe way to read back the Dock icon (see the tool gap) |
| NT-TG-002 | `screenshot shows other windows` | OPEN | Capture one window by id, never a screen region |
