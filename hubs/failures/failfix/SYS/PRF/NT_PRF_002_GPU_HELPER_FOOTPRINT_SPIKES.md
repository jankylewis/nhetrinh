# NT-PRF-002 — GPU helper footprint spikes in some runs — fix

id: NT-PRF-002
family: PRF
status: OPEN
date: 2026-11-16
source: _app/_Sources/NhetrinhReadback/_Steps/Budget.swift (`Budget.Reading`: median, highest sample)
source: _app/_Sources/NhetrinhReadback/_Steps/SystemSteps.swift `budgetHolds`, `memorySamples`
source: _app/Tests/NhetrinhReadbackTests/BudgetTests.swift
links: fix=yes lesson=no evidence=yes toolgap=none

## Fix that holds

The fix is in the measure, not in the app; the cause of a burst stays not proven (status OPEN).
R8 reads 5 memory samples 1 s apart after the 6 s settle and judges the MEDIAN app and the
MEDIAN total; the R8 line also shows the highest sample. The budget numbers are unchanged.
No sample is never a pass.

## The wrong fix

A later single sample: bursts came at 7, 25, 27 and 29 s too, so a later sample is not safer.

## Proof

Red first (the single-sample behaviour behind the new shape): a burst in 2 of 5 failed;
no sample passed; the highest sample was lost. Green after: a burst in 1 or 2 of 5 passes;
3 of 5 fails; a total or an app that grows in every sample fails.
Not proven: R8 with this code on the installed app (this seat may not start the app).
