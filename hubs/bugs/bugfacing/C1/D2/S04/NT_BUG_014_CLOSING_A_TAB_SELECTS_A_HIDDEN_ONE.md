# NT-BUG-014 — Closing a tab selects a hidden one

id: NT-BUG-014
family: TAB
status: OBSERVED
date: 2026-11-17
signature: closingTheSelectedTabSelectsAVisibleTab
source: _app/_Sources/_Nhetrinh/_Browser/_Window/BrowserWindowController+Tabs.swift on p7/prep e0b91ff (`close(at:)`)
observed: found by the P7 adversarial review (code read, then a test); no user report
links: fix=yes lesson=no evidence=no toolgap=none
cause: no failure reason filed: the mechanism is in the fix entry

## Steps

Rows r0, r1, then a collapsed folder A (a1). Select r1, close it.

Expected: r0 is selected: the nearest visible tab above, else below; a hidden tab only when none is visible (ruling P2).
Actual: a1, hidden inside the collapsed A, was selected (the next flat tab).
