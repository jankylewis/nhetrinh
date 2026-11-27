# NT-BUG-032 — a work site's account panel does not open

id: NT-BUG-032
family: WEB
status: NOT_A_BUG
date: 2026-11-27
signature: a click on the signed-in user's picture in a work site's header shows nothing
source: the headmate's screenshots (2026-11-23, 2026-11-27): the same page in nhetrinh (no panel) and in another
  browser (the panel opens under the picture); not kept here (work pages)
observed: on the installed 36db960, 2026-11-27
found_by: headmate (2026-11-23, "why nhetrinh cannot open this?")
links: fix=no lesson=no evidence=no toolgap=none

## Steps

1. Sign in to the work site (a code-hosting service of the work's cloud provider) in nhetrinh.
2. Open any page of it. 3. Click the user's picture at the right end of the site's header.

Expected: a panel under the picture: the organisation, Sign out, the name, View account, Switch directory.
Observed: nothing opens. The same with the sidebar on the left (not one of nhetrinh's views over the page);
at 100 % zoom too (2026-11-27 screenshot shows no zoom badge).

## Cause (not found)

Ruled out by reading the code (2026-11-23): no nhetrinh view over that corner (the address bar's list is hidden
and sits under the field); no frame or script load refused (only other apps' links are, `ExternalScheme`); no
error in the unified log. Not ruled out: a WebKit-only difference (the other browser may not use WebKit),
cross-site storage in a frame (WebKit's Storage Access API asks the app, and nhetrinh answers nothing), the user
agent. Needed: the page's Console errors on the click (Web Inspector is on: `isInspectable`), and Safari's result.

## Verdict (2026-11-27)

NOT_A_BUG of nhetrinh: the headmate saw the same in Safari (2026-11-27: "same for safari, cannot open too"); the
other browser that opens it is not built on WebKit (not proven). The site's panel fails on WebKit itself; nhetrinh
cannot fix it without pretending to be another browser, which it does not do.
