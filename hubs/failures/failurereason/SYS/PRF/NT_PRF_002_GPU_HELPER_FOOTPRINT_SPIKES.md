# NT-PRF-002 — GPU helper footprint spikes in some runs

id: NT-PRF-002
family: PRF
status: OPEN
date: 2026-11-16
signature: com.apple.WebKit.GPU above 40 MB, 6 s after one simple tab
source: hubs/failures/evidence/prf/_NT_PRF_001_RUNS.jsonl (`by_proc` rows)
links: fix=no lesson=no evidence=yes toolgap=none

## What is seen

The GPU helper is 16-20 MB in most runs. In 5 of 32 runs it was 44.7, 47.3, 51.5, 117.6 and
117.9 MB, with and without the runtime icon, on example.com and on the local page.
In 2 of them the app process was within budget, and the total still went past 110 MB (112.3, 204.4).
The R8 total of 140.2 MB may hold such a spike: not proven.

## Mechanism

Not proven. 5 runs had a second sample 10 s later; none of them spiked (GPU 18.6-18.9, then 13.8-19.1 MB),
so it is not known whether a spike falls with time.

## Confirm next time

Sample the GPU helper every second for 30 s after launch, in about 10 runs, and see if a spike falls.
If it falls: R8 can measure later or take the median of a few samples (a readback change).
