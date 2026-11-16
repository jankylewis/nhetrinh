# NT-ENV-001 — Bench burst peaked the machine

id: NT-ENV-001
family: ENV
status: OBSERVED
date: 2026-11-16
signature: whole machine at ~80% CPU during the bench
source: rnd/_bench/_bench.py scenario `tabs30` (`NHT_BENCH_LOADALL=1` with 30 URLs)
source: headmate report 2026-11-16 ("dont make my machine peak!", Activity Monitor screenshot)
observed: ~17 WebKit content processes at ~55% CPU each, system ~80% user CPU
links: fix=no lesson=yes evidence=yes toolgap=none

## Mechanism

`LOADALL` creates every tab's web view at once, so 30 pages load in parallel, each in its own process.
Fine on a lab machine, wrong on the headmate's working machine.

## Confirm

Activity Monitor during `tabs30`: many `https://...` WebKit processes, each near half a core.

Status OBSERVED: the run was stopped and the rule recorded; `bench.py` still loads all tabs at once (no fix yet).
