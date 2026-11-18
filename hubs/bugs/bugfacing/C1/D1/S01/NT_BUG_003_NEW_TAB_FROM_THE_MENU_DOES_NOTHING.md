# NT-BUG-003 — New Tab from the menu does nothing

id: NT-BUG-003
family: UIX
status: FIXED
date: 2026-11-16
found_by: readback (R5, R6 FAIL, readback 2026-11-16 18:57)
signature: after New Tab the sidebar has 1 rows, not 2
source: readback 2026-11-16 18:57, app 0.1.0 from commit 0d00e08 (`hubs/failures/evidence/readback/_LATEST.md` on branch `p0/harness-docs`)
observed: R5 FAIL "after New Tab the sidebar has 1 rows, not 2"; R6 FAIL "the sidebar has 1 row(s); 2 are needed"
links: fix=yes lesson=no evidence=yes toolgap=none
cause: NT-UIX-001

## Steps

Start nhetrinh without bringing it to the front (as the readback does, D18). Choose
File > New Tab through the Accessibility API.

Expected: a second row in the sidebar.
Actual: still one row. Every File, View and Tabs item has the same defect (NT-UIX-001); R6 fails
because it needs the second tab New Tab did not open.

Status OBSERVED: the fix is in the P0-FIX-1 change with a red-first test; not on `master`,
and not read back.
