# NT-NAV-002 — javascript: taken for another app

id: NT-NAV-002
family: NAV
status: OBSERVED
date: 2026-11-16
found_by: self-test (P2's `commandClickOpensABackgroundTab` red on the P3-FIX-1 merge)
signature: commandClickOpensABackgroundTab ... link → "javascript:void(0)"
source: _app/_Sources/NhetrinhCore/_Navigation/ExternalScheme.swift on p3/pages 1d391d9 (`staying`)
source: _app/Tests/NhetrinhTests/Tabs/RowAndLinkTests.swift `commandClickOpensABackgroundTab` (P2)
links: fix=yes lesson=no evidence=no toolgap=none

## Mechanism

P3's `ExternalScheme` kept six schemes in the browser; `javascript` was not one, so it "left": a
`javascript:` link reaching `decidePolicyFor` was cancelled and asked "No app on this Mac opens
javascript: links". P2 (built apart) expects such a link to run in its own page.

## Confirm

The merge of p2/sidebar into p3 (P3-FIX-1): P2's test failed on its `javascript:void(0)` case only.
