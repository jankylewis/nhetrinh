# Lightness report — 1.0 (P8)

status: DRAFT, P8-BUILD-1, 2026-11-17. The 1.0.0 build is not measured yet: its numbers come from R45
(the full readback on the installed 1.0.0) and R44 (R8 on the downloaded copy); fill the last column then.
Here because `hubs/product/plan/` is full (5 entries, each file at 100 lines); it stands next to the
R&D baseline it is measured against.

## The budget against the measured numbers

| Measure | Budget | R&D baseline | Last measured (R8, e0b5d3d) | 1.0.0 |
|---|---|---|---|---|
| App process, one simple tab | 40 MB | 34.5 MB | 32.2 MB, highest of 9 samples | not measured |
| App + all helpers, one simple tab | 110 MB | 95.7 MB | 90.0 MB, median of 9, 5 helpers | not measured |
| `nhetrinh.app` on disk | 1 MB (1024 KB) | 516 KB | 760 KB | not measured |
| Idle CPU, tabs open, nothing playing | 2 % | 1.3 % (10 sites) | 0.1 % (1 tab, 5 s) | not measured |
| 3 tabs, 2 unloaded: app (R38, P6) | 55 MB | — | 34.5 MB | not measured |
| 3 tabs, 2 unloaded: app + helpers (R38) | 125 MB | — | 102.8 MB, 6 helpers | not measured |

Sources: the budget, `plan/_PLAN.md` ("Lightness budget") and `plan/M3_V1_RELEASE.md` (P6's row);
the R&D baseline, `_bench/results/_RESULTS.md` (WebKit, 5 runs; idle CPU 3 runs of 10 sites), but its
516 KB bundle from `plan/DECISIONS.md` D2 and `plan/_PLAN.md` (not in `_RESULTS.md`);
the last measured, `hubs/failures/evidence/readback/_LATEST.md`, readback 00:34 on e0b5d3d (P7 merged
with P5 and P6). That build has neither P5-FIX-1 (p5/review) nor P7-FIX-1: not the release build.

## Across the phases (R8, one simple tab, from `hubs/failures/evidence/_INDEX.md`)

| Readback | App | App + helpers | Idle CPU | Bundle |
|---|---|---|---|---|
| P2, 22:34 | 30.5 MB | 88.5 MB | 0.3 % | 732 KB |
| P3, 22:55 | 30.9 MB | 88.5 MB | 0.1 % | 804 KB |
| P4, 23:20 | 31.1 MB | 88.5 MB | 0.1 % | 864 KB |
| P4-SIZE-1, 23:29 (`-Osize`, no exports, NT-PRF-005) | 31.1 MB | 88.7 MB | 0.1 % | 792 KB |
| P7, 00:34 (P5, P6, P7) | 32.2 MB | 90.0 MB | 0.1 % | 760 KB |

From P2 to P7: +1.7 MB in the app process and +1.5 MB in all, for sessions, folders, favicons, dialogs,
find, zoom, the Settings Hub, downloads and the memory guard. The bundle grew to 864 KB and came back to
760 KB with `-Osize`. Every row is inside the budget; the smallest margin is the bundle (264 KB left on
e0b5d3d; 812 KB on the P8 review's readback, 01:30 on e2bbc3f with P5-FIX-2: 212 KB left).

## How it is measured

- Memory: physical footprint (the number Activity Monitor shows) of the app and of every process macOS
  charges to it (`Footprint.swift`, NT-ENV-002). R8 takes 9 samples 1 s apart, 6 s after the page loads;
  the app on its highest sample, the total on its median, and a FAIL when the last 4 are all over the
  budget (NT-PRF-002: the GPU helper bursts for 1-3 s).
- Idle CPU: CPU time of the app and its helpers over 5 s, one tab, nothing playing.
- Bundle: allocated size on disk, as `du -sk` prints it. CI checks it on every build (`build.yml`).
- The R&D baseline is the benchmark's WebKit MVP (`_bench/`), measured before P0 on the same machine.

## Not measured, not proven

- The 1.0.0 build (above). The speed of page loads: never benchmarked (D2).
- Idle CPU with many tabs in the app itself: R8 measures one tab; the 10-site number is the R&D MVP's.
- Memory under real pressure: R36-R38 simulate it (D23); real system pressure is never made.
- The cost of the outline sidebar's reload at every chrome refresh (P7, R-11): not measured on its own.
