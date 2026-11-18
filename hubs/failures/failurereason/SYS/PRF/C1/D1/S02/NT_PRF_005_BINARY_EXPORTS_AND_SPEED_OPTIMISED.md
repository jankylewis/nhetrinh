# NT-PRF-005 — Binary exports and speed optimised

id: NT-PRF-005
family: PRF
status: OBSERVED
date: 2026-11-16
note: filed as NT-PRF-003 on p4/tools; renumbered at the P3 merge (P4-MERGE-1): p3/pages had taken 003 and 004
signature: bundle 864 KB (max 1024)
source: hubs/failures/evidence/readback/_LATEST.md (R8 row, P4 run 23:20, build 3fd21ed)
source: _app/scripts/_build.sh (`-Xswiftc "$OPT" -Xlinker -no_exported_symbols`, the export check after `strip`)
source: _app/assets/_icon/tools/make_icns.sh, tools/nearest.swift (P4-SIZE-2, icon ruling: option C)
observed: P4-SIZE-1, 2026-11-16, release builds of p4/tools 4488cd6+ (app code unchanged), binary after `strip`:
observed: `-O` 513888 B, 494 exported symbols | `-Osize` 481504 B | `-O -no_exported_symbols` 472160 B, 0 exported
observed: `-Osize -no_exported_symbols` 439776 B, 0 exported (installed copy: 437392 B)
links: fix=yes lesson=no evidence=yes toolgap=none

## Mechanism

The bundle is 864 KB of the 1 MB budget with P5 to P8 still to come: the binary 511 KB,
`AppIcon.icns` 344 KB, `AppIcon.png` 17 KB. Two parts of the binary were not needed:
- 494 exported symbols: an executable exports every global symbol, and NhetrinhCore's API is
  `public` (since the D23 probe, the follow-up named in P0-PROBE); `strip -x` keeps globals.
  An app with no plugins needs none of them: -41.7 KB.
- `-O` optimises for speed; `-Osize` for size: -32.4 KB alone, -74.1 KB with the exports gone.
SwiftPM's release link already passes `-dead_strip`; `strip -S` removed nothing more.

## Confirm

`du -sk` of the installed bundle: 864 (build 3fd21ed, `-O`, exports) -> 824 (`NHT_OPT=-O`, no
exports) -> 792 (`-Osize`, no exports). R8 on each (terminal, 2026-11-16):
- `-O`, no exports: app 31.6 MB, app + 5 helpers 88.2 MB, idle CPU 0.1 %, bundle 824 KB.
- `-Osize`, no exports (full run 23:29, 30 PASS): app 31.1 MB, app + 5 helpers 88.7 MB, idle CPU
  0.1 %, bundle 792 KB. Before (P4 run 23:20, `-O`, exports): 31.1 MB, 88.5 MB, 0.1 %, 864 KB.
Not proven: a speed cost of `-Osize`; R8 measures memory, CPU at idle and size, not speed.

## Fix

`_build.sh` builds with `-Osize` (`NHT_OPT=-O` compares) and `-no_exported_symbols`, and fails when
the stripped app exports any symbol.

## Icon (P4-SIZE-2)

`make_icns.sh` smoothed every size with `sips -z`; only the 1024 px image kept the hard pixels of
the 80 px grid. Now 128 px and up are the grid drawn nearest-neighbour (`nearest.swift draw`), with
the smallest ImageIO PNG filter; 16, 32, 64 stay smoothed (a nearest downscale drops grid cells).
`nearest.swift check` proves the shipped sizes from 128 up equal the grid, pixel for pixel, and the
grid drawn at 1024 equals the master; it fails on the old iconset (`icon_128x128.png`, exit 1).
16, 32, 64: 4 of 4 pixel-identical to the old files. `_DockIcon.png`: byte-identical, unchanged.
`AppIcon.icns` 343577 -> 147081 B; bundle (`du -sk`, release build) 792 -> 600 KB.
The look changes at 128, 256 and 512 px only: hard pixels like the 1024 master, no longer blurred.

## CI, 2026-11-18: one export on the macos-15 runner

PR #7 CI failed: `the app exports 1 symbols`. The check now names them: `T __mh_execute_header`,
the Mach-O header every executable carries. The macos-15 linker lists it as exported, the local
toolchain (Swift 6.4.2) does not. It is not an API we export, so `_build.sh` leaves that one
symbol out of the count and prints any other export by name.
