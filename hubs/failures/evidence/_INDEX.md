# evidence

One row per kept evidence path (a file per id only past 3 paths).

| Id | Path | What it shows | Capture next time |
|---|---|---|---|
| NT-ENV-001 | `hubs/product/rnd/_bench/results/raw.jsonl` (`tabs30_loaded` rows) | 2 of 3 runs before the stop; ~2.4 GB (WebKit) vs ~4.9 GB (Chromium) | CPU % per run |
| NT-BLD-001 | `_app/assets/_icon/_AppIcon.png` | the transparent pixel icon now set at runtime | a Dock readback (NT-TG-001) |
| NT-PRF-* | `hubs/product/rnd/_bench/results/_RESULTS.md` | WebKit vs Chromium: startup, memory, idle CPU | speed benchmarks (skipped by headmate decision) |
| readback (R1-R8) | `hubs/failures/evidence/readback/_LATEST.md` | the verdict per step of the last full readback on the installed app; written only by a full run (`cd _app && swift run nhetrinh-readback`) | a run with the Accessibility permission granted |
| NT-PRF-001 | `prf/_NT_PRF_001_RUNS.jsonl`, `prf/measure.py` | 32 runs: icon, icon size, profile, page, build; per-process MB | R8 on the installed app after the fix |
| NT-PRF-002 | `prf/_NT_PRF_001_RUNS.jsonl` (`by_proc`, GPU) | GPU helper 45-118 MB in 5 of 32 runs | GPU every second for 30 s, about 10 runs |
