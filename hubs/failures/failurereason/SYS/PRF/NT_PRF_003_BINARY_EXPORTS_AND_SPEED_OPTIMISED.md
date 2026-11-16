# NT-PRF-003 — Binary exports and speed optimised

id: NT-PRF-003
family: PRF
status: OBSERVED
date: 2026-11-16
signature: bundle 864 KB (max 1024)
source: hubs/failures/evidence/readback/_LATEST.md (R8 row, P4 run 23:20, build 3fd21ed)
source: _app/scripts/_build.sh (`-Xswiftc "$OPT" -Xlinker -no_exported_symbols`, the export check after `strip`)
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
the stripped app exports any symbol. Not done here (outside the binary): the 344 KB `.icns`.
