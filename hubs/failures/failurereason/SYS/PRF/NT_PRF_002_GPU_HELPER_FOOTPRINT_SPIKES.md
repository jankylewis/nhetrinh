# NT-PRF-002 — GPU helper footprint spikes in some runs

id: NT-PRF-002
family: PRF
status: OPEN
date: 2026-11-16
signature: com.apple.WebKit.GPU above 40 MB, 6 s after one simple tab
source: hubs/failures/evidence/prf/_NT_PRF_001_RUNS.jsonl (`by_proc` rows)
source: hubs/failures/evidence/prf/NT_PRF_002_GPU_SAMPLES.jsonl (8 runs x 30 samples, `gpu_samples.py`)
links: fix=yes lesson=no evidence=yes toolgap=none

## What is seen

The GPU helper is 13-20 MB at rest. It jumps to 116-122 MB for 1-3 s, then falls back at once.
- Every one of 8 runs had a burst in its first 1-3 s after launch.
- After 6 s, 5 of 200 samples (2.5 %) caught a burst (runs 5 and 7, at 7-8 s, 25 s, 27 s, 29 s).
- Every sample that caught a burst had a total over 110 MB. Without a burst, the highest total was 97.5 MB
  and the highest app process 37.7 MB (installed app, commit 41b7e3b, example.com, profile readback).
- A burst does not fade with time. It comes and goes, so a later single sample is not safe either.
- Earlier runs (`_NT_PRF_001_RUNS.jsonl`): 5 of 32 single samples caught one, with and without the icon.

## Mechanism

Not proven. The bursts look like a short-lived GPU buffer (about 100 MB) in the GPU helper;
which work makes it is not known. Nothing shows that nhetrinh's own code causes it.

## Proposal for R8 (a readback change; the budget stays)

After the 6 s settle, take 5 samples 1 s apart and compare the MEDIAN app and MEDIAN total
with the budget. Over these 8 runs, the worst 5-sample median after 6 s was 97.5 MB total
(budget 110): no 5-sample window after 6 s held more than 2 burst samples. Bursts closer
together could still move a median of 5: not seen, not excluded.
Keep the highest sample in the R8 line as information, so a real growth is still seen.
