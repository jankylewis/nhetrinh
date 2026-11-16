# NT-GAT-003 — Readback reports more than it ran — fix

id: NT-GAT-003
family: GAT
status: OBSERVED
date: 2026-11-16
source: _app/_Sources/NhetrinhReadback/main.swift (`Options.init(_:known:)` throws `UsageError`; exit 2)
source: _app/_Sources/NhetrinhReadback/Report.swift (`INCOMPLETE (no step ran)`, exit 2; `tilde(_:home:)`)
source: _app/Tests/NhetrinhReadbackTests/OptionsTests.swift `optionsSelectAppAndSteps`, `badCommandLineIsAUsageError`, `repeatedFlagIsAUsageError`
source: _app/Tests/NhetrinhReadbackTests/ReportTests.swift
source: _app/_Sources/NhetrinhReadback/Options.swift `UsageError.init(message:)`, main.swift "no app at" (P0-RBK-5)
source: _app/Tests/NhetrinhReadbackTests/OptionsTests.swift `usageErrorNamesNoPersonalPath` (commit 88a9953, red)
links: fix=yes lesson=no evidence=no toolgap=none

## Fix that holds

- A flag other than `--app` or `--steps`, a flag without a value, an empty step list or an
  unknown step id is a usage error: it prints the usage and exits 2 before any step runs.
- A flag given more than once is a usage error too (it kept only its last value).
- A run where no step ran is `INCOMPLETE (no step ran)`, exit 2: nothing read back is never a pass.
- `tilde` replaces the home folder only as a whole path part.
- Every `UsageError` message passes through `Report.tilde` when it is made, and so does the
  "no app at" line: no home path reaches stderr or the app log (law 8).
- Run cases: FAIL with NOT READ BACK, the worst verdict first and last, no step.

## Proof

Red first (`_app/scripts/test.sh`, the new shapes with the old behaviour): 7 of 7 bad command
lines ran; the empty run gave PASS and exit 0; `tilde` failed `/Users/someone2` and `/Users/someone.old`.
Then green. Two cases where the code was already right were proven able to fail by mutation:
"NOT READ BACK checked before FAIL" fails 2 cases; "only the last step counts" fails 4.
Repeated flags: red at commit 90b8cab (2 issues in `repeatedFlagIsAUsageError`), then green.
Home path in a usage error: red at commit 88a9953 (`usageErrorNamesNoPersonalPath`), green with P0-RBK-5.

Not proven: a readback run with the new code (this seat may not start the app).
