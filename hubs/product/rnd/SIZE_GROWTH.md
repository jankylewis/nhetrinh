# What grows the app's size

status: RULED 8A, 2026-11-28 (D32). Measured 2026-11-27 for the headmate's size ruling.

## How it was measured

Each tag and branch was built the same way: `swift build -c release --arch arm64 --product Nhetrinh -Xswiftc -Osize
-Xlinker -no_exported_symbols`, then `strip -x` (as `_build.sh`). One build at a time, `nice -n 10`, in a scratch
worktree. Lines: every `.swift` file under `_app/_Sources` (the app, the core and the readback tool).

## The binary per phase

| Build | Binary (stripped) | Grew by | Source lines | Bytes per line |
|---|---|---|---|---|
| v0.1.0 (P0) | 154 KB | - | 1,939 | 81 |
| v0.2.0 (P1 tabs come back) | 256 KB | +102 KB | 2,995 | 88 |
| v0.3.0 (P2 sidebar) | 329 KB | +73 KB | 3,990 | 84 |
| v0.4.0 (P3 page basics) | 396 KB | +67 KB | 4,986 | 81 |
| v0.5.0 (P4 find, zoom) | 431 KB | +35 KB | 5,809 | 76 |
| v0.6.0 (P5 downloads) | 533 KB | +102 KB | 6,861 | 80 |
| v0.7.0 (P6 memory guard) | 551 KB | +18 KB | 7,204 | 78 |
| v0.8.0 (P7 groups) | 641 KB | +90 KB | 8,267 | 79 |
| p8/release (nested groups, font, side) | 726 KB | +85 KB | 9,875 | 75 |
| p9/remember (sign-ins) | 793 KB | +67 KB | 10,580 | 77 |
| p11/history (history, dropdown) | 862 KB | +69 KB over p9 | 11,689 | 75 |
| p10/profile (profiles) | 826 KB | +33 KB over p9 | 11,025 | 77 |
| p12/combine (all of the above) | 895 KB | - | 12,000 | 76 |

The bundle adds the icon (107 KB `AppIcon.icns`, 16 KB `AppIcon.png`) and 5 KB of plist and signature: p11/history
1,012 KB (D31), p12/combine about 1,044 KB.

## Findings

- Nothing jumped: the binary grows with the code, steadily about 76 bytes per source line, at every phase.
  No library, no resource and no build setting change made a step. Every feature costs its own lines.
- Already on: `-Osize`, `-dead_strip` (SwiftPM release), no exported symbols, `strip -x`.
- Inside p11/history's binary (linker map): the app module 420 KB, the core 302 KB, the linker's own 43 KB.
  By kind: generic specializations 97 KB, type metadata and witnesses 103 KB, closures 43 KB, Codable 26 KB.
- Readback-only code ships in the app: the probe about 68 KB (core 42 KB, app 26 KB: `*Probe*` files) and the
  timing hooks (`Bench`) 14 KB. It is there on purpose (D23): the readback drives the installed app itself.
- Not measured: how much each source line costs by feature inside one phase.

## Size options reviewed for D32

| Way | Saves | Cost |
|---|---|---|
| Raise the budget to 1.1 MB | - | the rule moves; the curve keeps rising about 70 KB a phase |
| Build the probe and the timing hooks only into a readback build | about 82 KB | the readback no longer checks the very binary the user runs (against D23) |
| Trim Codable (hand-written JSON for the session and prefs) | part of 26 KB, not measured | more code to test, small gain |
