# NT-ENV-002 — Terminal launch hides WebKit helpers — fix

id: NT-ENV-002
family: ENV
status: FIXED
date: 2026-11-16
source: rnd/_bench/_bench.py `launch`
links: fix=yes lesson=yes evidence=no toolgap=none

## Fix that holds

`open -n -F --env ... <app>`, then find the pid with `pgrep -x`.

## Proof

Same app, same page: 1 process / 35 MB from a terminal; 6 processes / 145 MB via `open` (2026-11-16 run).
