# NT-ENV-003 — Relaunch before helpers exit — fix

id: NT-ENV-003
family: ENV
status: FIXED
date: 2026-11-16
source: hubs/product/rnd/_bench/_bench.py `wait_clean`, `kill`
links: fix=yes lesson=yes evidence=no toolgap=none

## Fix that holds

Kill the app and its helpers, poll until none is left, wait 3 s, then launch.

## Proof

`hubs/product/rnd/_bench/results/raw.jsonl`: 10 startup runs, all between 0.4 and 1.1 s.
