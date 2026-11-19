# NT-BUG-020 — A sign-in is lost after quit and relaunch

id: NT-BUG-020
family: TAB
status: OBSERVED
date: 2026-11-18
signature: sign-ins: restored 0
source: BRIEF_P9_REMEMBER.md (matemaster brief, outside the repository): "after quit and relaunch they must sign in again"
source: hubs/product/plan/DECISIONS.md D28 (the headmate's measurement)
observed: reported by the headmate on the installed app, 2026-11-18; no screen capture kept
found_by: headmate (2026-11-18, P9-REMEMBER brief: "must sign in again")
links: fix=yes lesson=no evidence=no toolgap=none

## Steps

Sign in to a site whose sign-in lives in a session cookie (no expiry). Quit nhetrinh, open it again, open the site.

Expected: still signed in, as Chrome and Firefox are with session restore on.
Actual (849c3e3, headmate): the site asks to sign in again.

## Cause

WebKit writes dated cookies to disk but never a session cookie (the headmate's measurement, D28). nhetrinh kept
nothing across a quit. Not proven in the repository: a run on the installed app (R51 is not read back).

## Observed again (2026-11-19, found_by: headmate)

After the reinstall of d826c82 the headmate's work site asked to pick an account again. The Keychain check that
followed found no item, but it ran after the next launch, which restores the item and deletes it: it proved
nothing. On 2026-11-19 (b3d0e32) the item was there after the headmate's quit (exit 0) and gone after the launch
(exit 44): the save and the restore both ran. Cause of the account picker not proven (not every sign-in is a
session cookie; restore counts are not persisted in the log).
