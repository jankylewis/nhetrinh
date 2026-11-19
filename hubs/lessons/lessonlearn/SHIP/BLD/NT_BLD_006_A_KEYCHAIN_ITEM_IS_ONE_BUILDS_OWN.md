# NT-BLD-006 — A Keychain item is one build's own — lesson

id: NT-BLD-006
family: BLD
status: OBSERVED
date: 2026-11-18
found_by: development (P9-REMEMBER review, 2026-11-18)
links: fix=yes lesson=yes evidence=no toolgap=none

## Believed

`LAContext.interactionNotAllowed` makes every Keychain call quiet, and a later build reads the item an
earlier build wrote, as the same app.

## What changed it

Two ad-hoc builds of a scratch tool against a scratch keychain file: the second could not read, delete or
replace the first one's item; it could only overwrite it.

## Rule

An ad-hoc-signed app is a new app to the Keychain at every build: anything it must keep across a reinstall
needs a stable signature (the local identity). Test a stored secret across two builds, with user interaction
off, on a scratch keychain, never the login one; and test the calls the code makes through a seam, not only
the helpers (RECHECK_P9_REMEMBER.md D1). Builds of different signatures never share an item: an overwrite is
allowed where a read is not, so a shared item can be fed forever and never read (P9-REMEMBER-2).
