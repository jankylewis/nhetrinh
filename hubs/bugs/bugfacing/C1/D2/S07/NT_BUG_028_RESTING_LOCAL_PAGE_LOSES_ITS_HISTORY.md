# NT-BUG-028 — a local page that rests comes back without its history

id: NT-BUG-028
family: NAV
status: OBSERVED
date: 2026-11-21
signature: aRestingLocalPageComesBackWithItsHistory
source: NT-BUG-026's "not read back" note; `LocalPageTests` in the test process
observed: in the test process, 2026-11-21, on e840ac6: after the rest, back was off ("title b, back false")
found_by: self-test (2026-11-21, a family sweep of NT-BUG-026 and NT-BUG-027 while the headmate slept)
links: fix=yes lesson=no evidence=no toolgap=none

## Steps

1. Open a local page and follow a link to a second local page.
2. Let the tab rest (Put Tab to Idle, or its minutes pass), then show it again.

Expected: the second page, and Back works, as for a web page. Observed: the second page, and Back is off.

## Cause

`load` skipped the kept history (`interactionState`) for a local page and loaded the file again. NT-BUG-026
assumed WebKit could not read a file through restored history. That was not true.

## Fix

- `load` restores the kept history for every page. WebKit gives a restored local page its read access: the
  test reads the page's text, its `../` style, and the first page after Back, all from disk.
- Test: `aRestingLocalPageComesBackWithItsHistory` (red on e840ac6; red again with the old code: mutation check).

Not read back: needs the installed app. Not proven: a page helper WebKit starts new for the restore, rather than
one it reused; the test cannot choose which.

Status OBSERVED, not FIXED (2026-11-27): the fix is on a branch, not on `master` yet (`hubs/_SCHEMA.md`).
It becomes FIXED at the merge to `master`.
