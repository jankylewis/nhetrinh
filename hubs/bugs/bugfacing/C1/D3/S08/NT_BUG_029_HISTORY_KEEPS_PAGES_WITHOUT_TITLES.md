# NT-BUG-029 — history keeps pages without their titles

id: NT-BUG-029
family: NAV
status: OBSERVED
date: 2026-11-22
signature: the dropdown's first row is "<url> — <url>"
source: readback R54 FAIL on the installed fe657c9 (2026-11-22): the readback profile's three rows had empty
  titles; the headmate's own history: 33 of 88 rows without a title (counted only, no row read)
observed: on the installed fe657c9, 2026-11-22
found_by: readback (R54, 2026-11-22, first run after the headmate's OK to own the app)
links: fix=yes lesson=no evidence=no toolgap=none

## Steps

1. Visit a page. 2. Type part of its title in the address bar.

Expected: a row "<title> — <url>". Observed: "<url> — <url>", or no row when only the title matches.

## Cause

The visit is kept at `didFinish` with `webView.title`. WebKit often reports the title after `didFinish`: the
test process saw it every time (5 of 5). An empty title was kept, and nothing filled it later.

## Fix

- `HistoryStore.retitle`: a title reported later fills a row that has none; a kept title stays, so a page whose
  title keeps changing writes nothing. The title observer calls it (`retitleVisit`).
- Rows already empty fill at their next visit.
- Tests: `aLoadedPagesTitleReachesTheHistory` (a real web view, 5 rounds; red before the fix, red again with
  the call removed: mutation check), `aLateTitleFillsOnlyARowWithout`.

Read back: R54 PASS on the installed cd9b848 (2026-11-22; FAIL on fe657c9 the same morning).

Status OBSERVED, not FIXED (2026-11-27): the fix is on a branch, not on `master` yet (`hubs/_SCHEMA.md`).
It becomes FIXED at the merge to `master`.
