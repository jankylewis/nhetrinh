# NT-ENV-003 — Relaunch before helpers exit

id: NT-ENV-003
family: ENV
status: FIXED
date: 2026-11-16
found_by: development (bench runs, a slow first load after a kill)
signature: first_load 8-10 s for one run, under 1 s for the next
source: hubs/product/rnd/_bench/_bench.py `wait_clean`
observed: the Chromium MVP took 8.3 s and 10.7 s to first load right after a kill, then 0.88 s once the old processes were gone
links: fix=yes lesson=yes evidence=no toolgap=none

## Mechanism

Not proven in detail: the old instance's helpers were still alive when the next run started; Chromium waits on its profile.

## Fix

Before every launch, wait until the app and all helper processes are gone, plus 3 s.
