# NT-BUG-027 — a local page cannot load or open files above its folder

id: NT-BUG-027
family: NAV
status: FIXED
date: 2026-11-21
signature: aLocalPageReadsAndOpensItsParentsFiles
source: `LocalPageTests` in the test process; the storybook pages (`hubs/product/storybooks/`) use `../` links
observed: in the test process, 2026-11-21, on d355a1e: the style did not apply (margin 8px, not 37px) and the
  link showed "This page could not be loaded"
found_by: self-test (2026-11-21, a new test written while the headmate was away; storybook pages in subfolders link with `../`)
links: fix=yes lesson=no evidence=no toolgap=none

## Steps

1. Open `sub/page.html` from Finder. It loads `../style.css` and links to `../other.html`.
2. Click the link.

Expected: the style applies and the link opens. Observed: no style, and an error page.

## Cause

NT-BUG-026 gave a local page read access to its own folder only (`IncomingLink.readAccess`). WebKit then
refused every file above it: styles, pictures, scripts and links.

## Fix

- `readAccess` gives the whole disk (`/`), as Safari does. A page's script still cannot read another file:
  WebKit keeps file pages apart (`fetch` answers "blocked" in the test).
- Tests: `aLocalPageReadsAndOpensItsParentsFiles` (red on d355a1e; red again with the old rule: mutation check),
  `aLocalPageLoadsFilesAboveItsFolder`.

Read back: R55 PASS on the installed fe657c9 (2026-11-22): `sub/page.html` read `../s.css` (its script set the
title "margin 37px") and its `../other.html` link opened. Not shown: R55 red on an older build (a second app copy
confuses the default browser list; the unit test's mutation check covers the rule). The "blocked" check was not
shown to fail: WebKit's file setting cannot change in the test process.
