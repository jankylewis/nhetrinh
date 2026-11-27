# NT-BUG-026 — macOS does not treat nhetrinh as a browser

id: NT-BUG-026
family: BLD
status: OBSERVED
date: 2026-11-21
signature: not in the default web browser list
source: the headmate's report, 2026-11-21 (matemaster session, outside the repository); the installed Info.plist
  compared with four browsers' (Chrome, Brave, Firefox, Zen) on the same Mac
observed: on the installed app (0dbca37), 2026-11-21; `NSWorkspace.urlsForApplications` did list it for http(s)
found_by: headmate (2026-11-21, "nhetrinh will not be in default app selection that i can choose?")
links: fix=yes lesson=no evidence=no toolgap=none

## Steps

System Settings > Desktop & Dock > Default web browser.

Expected: nhetrinh is in the list. Observed: it is not.

## Cause (the family)

The Info.plist (`_app/scripts/_build.sh`) claimed web links only (`http`, `https`). Every browser compared also
claims HTML files, `file` links and Handoff (`NSUserActivityTypeBrowsingWeb`); apps that claim links only (a chat
app, a web-app wrapper) are not browsers to macOS either. Each missing claim leaves nhetrinh out somewhere:
the default browser list and Finder's Open With (HTML files), another app's link to a local file (`file`), a page
handed off from another device (Handoff). `openIncoming` also dropped every link but `http(s)`.

## Fix

- Info.plist claims `file`, `public.html`, `public.xhtml` (Viewer) and `NSUserActivityTypeBrowsingWeb`; the build
  stops when a claim is missing (`browser_claims`; red on the 0dbca37 plist: "lacks file").
- `IncomingLink` (core) is the one list: web pages and local files open as tabs; a local page reads its own folder
  only (`loadFileURL`); that was too narrow, see NT-BUG-027. Not proven needed: a plain load of the file also showed it in the tests (mutation check).
- Handoff: `AppDelegate.continueBrowsing` opens the page as a tab.
- Tests: `incomingLinksAreWebPagesOrFiles`, `aLocalPageReadsItsOwnFolder` (now `aLocalPageLoadsFilesAboveItsFolder`), `LocalPageTests`.

Read back: on 2026-11-21 the headmate set nhetrinh as the default web browser in System Settings (installed
d355a1e), and opened the storybook from it. Not read back: Open With and Handoff. A local page lost its back / forward history when its tab went idle: fixed in NT-BUG-028.

Status OBSERVED, not FIXED (2026-11-27): the fix is on a branch, not on `master` yet (`hubs/_SCHEMA.md`).
It becomes FIXED at the merge to `master`.
