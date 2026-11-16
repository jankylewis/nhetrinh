# NT-PRF-002 — GPU helper footprint spikes in some runs — fix

id: NT-PRF-002
family: PRF
status: OPEN
date: 2026-11-16
source: _app/_Sources/NhetrinhReadback/_Steps/Budget.swift (`Budget.Reading`: median, rise, highest sample)
source: _app/_Sources/NhetrinhReadback/_Steps/SystemSteps.swift `budgetHolds`, `memorySamples`
source: _app/Tests/NhetrinhReadbackTests/BudgetTests.swift `memoryBudgetJudgesTheSamples`, `memoryBudgetReviewGaps`
links: fix=yes lesson=no evidence=yes toolgap=none

## Fix that holds

The fix is in the measure, not in the app; the cause of a burst stays not proven (status OPEN).
R8 reads 9 memory samples 1 s apart after the 6 s settle. A burst lasts at most 3 s, so it can
never move a median of 9. The TOTAL is judged on its MEDIAN, and also fails when the last 4
samples are all over the budget (a rise, longer than any burst seen). The APP process is judged
on its HIGHEST sample: no app-process burst was ever seen (highest 37.7 MB in
`NT_PRF_002_GPU_SAMPLES.jsonl`). The R8 line also shows the highest sample. The budget numbers
are unchanged. No sample is never a pass.

## The wrong fix

A later single sample: bursts came at 7, 25, 27 and 29 s too, so a later sample is not safer.
A median of 5 (commit 4ee85bf): one 3 s burst covers 3 of 5 and fails it; the app process judged
on its median let an app over 40 MB in 2 of 5 pass.

## Proof

Red first (the single-sample behaviour behind the new shape): a burst in 2 of 5 failed;
no sample passed; the highest sample was lost. Green after: a burst in 1 or 2 of 5 passes;
3 of 5 fails; a total or an app that grows in every sample fails.
Median of 5 red at commit 90b8cab: 3 issues in `memoryBudgetReviewGaps`. Green after, 9 samples.
The case "the app bursts in 1 of 9" now expects a fail (it expected a pass on the median).
Mutation: no rise check, or the app on its median, each fails a case. Replayed on the 8 runs of
`NT_PRF_002_GPU_SAMPLES.jsonl` (every 9-sample window): 1 of 176 fails, the window from 1 s after
launch in run 7 (5 of 9 samples in bursts); R8 samples only after the 6 s settle.
Not proven: R8 with this code on the installed app (this seat may not start the app).
