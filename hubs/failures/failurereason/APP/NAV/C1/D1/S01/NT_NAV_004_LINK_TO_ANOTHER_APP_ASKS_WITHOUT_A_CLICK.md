# NT-NAV-004 — Link to another app asks without a click

id: NT-NAV-004
family: NAV
status: OBSERVED
date: 2026-11-16
found_by: development (P3-REVIEW P3, from the code)
signature: followed = ... || action.targetFrame?.isMainFrame != false
source: _app/_Sources/_Nhetrinh/_Browser/_Window/BrowserWindowController+WebKit.swift (`decidePolicyFor`)
links: fix=no lesson=no evidence=no toolgap=none

## Mechanism

Any main-frame load of a scheme that leaves the browser asks, not only a click: a page that sets
`location = 'mailto:…'` on a timer queues one ask sheet after another. Subframes are refused quietly.

## Confirm

From the code (P3-REVIEW P3). Not run. Fix waits for a ruling: ask only for `.linkActivated`?
