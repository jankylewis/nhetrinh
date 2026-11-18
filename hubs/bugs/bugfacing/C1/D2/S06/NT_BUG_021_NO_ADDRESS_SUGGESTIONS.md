# NT-BUG-021 — The address bar shows no visited pages

id: NT-BUG-021
family: NAV
status: OBSERVED
date: 2026-11-18
signature: typing https shows nothing
source: hubs/product/plan/DECISIONS.md D30
observed: The headmate reported that typing `https` in the address bar shows nothing.
found_by: headmate (2026-11-18, P11-HISTORY brief: "Typing https in the address bar shows nothing")
links: fix=yes lesson=no evidence=no toolgap=none

## Steps

Visit a site, then type part of its address in the address bar.

Expected: a dropdown under the address bar offers the visited page.
Actual: the headmate saw no dropdown. The installed app has not been read back after P11-HISTORY.

## Cause

The earlier app kept only each tab's back and forward list; it had no page history store or address suggestions.
The P11-HISTORY code adds both; live behavior is not proven until R54 runs on the installed app.
