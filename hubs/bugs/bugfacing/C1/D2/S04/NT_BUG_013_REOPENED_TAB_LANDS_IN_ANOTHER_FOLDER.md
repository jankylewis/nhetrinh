# NT-BUG-013 — A reopened tab lands in another folder

id: NT-BUG-013
family: TAB
status: FIXED
date: 2026-11-17
found_by: development (P7 review)
signature: reopenPutsTheTabBackWhereItWas
source: _app/_Sources/_Nhetrinh/_Browser/Handling/_TabHandling.swift on p7/prep e0b91ff (`reopenClosedTab`: `insert(atFlat:)`)
observed: found by the P7 adversarial review (code read, then a test); no user report
links: fix=yes lesson=no evidence=no toolgap=none
cause: no failure reason filed: the mechanism is in the fix entry

## Steps

Folders A (a1) and B (b1, b2). Close b1, then File > Reopen Closed Tab.

Expected: b1 is back first in B, selected (ruling P1).
Actual: b1 came back inside A (`[A:a1,b1, B:b2]`); a root tab after a folder went into the folder; the last tab of the last folder came back at the root.

Status FIXED (2026-11-27): the fix's test is on `master`, and its phase passed the full readback of
2026-11-17 13:19 (`hubs/product/plan/_PLAN.md`).
