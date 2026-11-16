# evidence

One row per kept evidence path (a file per id only past 3 paths).

| Id | Path | What it shows | Capture next time |
|---|---|---|---|
| NT-ENV-001 | `hubs/product/rnd/_bench/results/raw.jsonl` (`tabs30_loaded` rows) | 2 of 3 runs before the stop; ~2.4 GB (WebKit) vs ~4.9 GB (Chromium) | CPU % per run |
| NT-BLD-001 | `_app/assets/_icon/_AppIcon.png` | the transparent pixel icon now set at runtime | a Dock readback (NT-TG-001) |
| NT-PRF-* | `hubs/product/rnd/_bench/results/_RESULTS.md` | WebKit vs Chromium: startup, memory, idle CPU | speed benchmarks (skipped by headmate decision) |
| readback (R1-R8) | `hubs/failures/evidence/readback/_LATEST.md` | the verdict per step of the last full readback on the installed app; written only by a full run (`cd _app && swift run nhetrinh-readback`) | a run with the Accessibility permission granted |
| NT-PRF-001 | `prf/_NT_PRF_001_RUNS.jsonl`, `prf/measure.py` | 32 runs: icon, icon size, profile, page, build; per-process MB | R8 on the installed app after the fix |
| NT-PRF-002 | `prf/NT_PRF_002_GPU_SAMPLES.jsonl`, `prf/gpu_samples.py` | 8 runs x 30 s: GPU bursts of ~100 MB for 1-3 s | the work that makes a burst (not known) |
| NT-UIX-001 | `hubs/failures/evidence/readback/_LATEST.md` (branch `p0/harness-docs`, run 18:57) | R5, R6 FAIL: New Tab from the menu added no row | R5 and R6 after the fix (P0-FIX-1) |
| NT-GAT-006 | `hubs/failures/evidence/readback/_LATEST.md` (branch `p0/harness-docs`, run 19:27) | R6 NOT READ BACK: -25202 on `AXSelected` | R6 after the fix, on the next rebuild |
| R2 (19:28) | none kept: the capture was deleted | R2 FAIL on the running app's item, agreement 77 %, scale 84 %; the headmate sees no tile | see NT-GAT-007 |
| NT-GAT-007 | outside the repository only: the 19:40 `--keep-capture` folder (PNG shows other apps' icons; never copied in) | R2 FAIL 76 %: item 34 x 22 pt on a left Dock, a lighter strip past the Dock's edge | R2 after the fix, on the next rebuild |
| readback P1 (22:13) | `hubs/failures/evidence/readback/_LATEST.md` (terminal, full run) + R2 line below | build cb22afe+ (p1/session with p0/probe merged, uncommitted): R1, R3-R12 PASS, R2 NOT READ BACK (terminal has no Accessibility; exit 2). R2 from the installed nhetrinh-readback.app (night ruling: the gate counts it): `R2 PASS: captured the Dock item (34 x 22 pt) and a ring inside the Dock, not kept: silhouette agreement 96 %, icon at 92 % of the Dock item`, exit 0 | one full run with R2 in it (granted app, `readback_app.sh run`) |
