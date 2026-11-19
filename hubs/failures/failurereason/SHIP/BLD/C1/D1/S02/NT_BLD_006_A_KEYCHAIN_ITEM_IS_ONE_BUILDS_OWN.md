# NT-BLD-006 — A Keychain item is one build's own

id: NT-BLD-006
family: BLD
status: OBSERVED
date: 2026-11-18
signature: keychain status -25293
source: _app/scripts/_build.sh on 849c3e3 (`codesign --force --sign -`: ad-hoc, a new code hash every build)
source: _app/_Sources/_Nhetrinh/Support/Secrets.swift on the P9-REMEMBER diff (one item, `LAContext` only)
observed: reviewer experiment, a scratch keychain file (search list unchanged), two ad-hoc builds A and B of
  one tool, user interaction off: B reads A's item -25293, deletes it -25244, adds its own -25299 (duplicate),
  updates A's item 0. Under `designated => identifier`: B reads 0, deletes -25244 (REVIEW_P9_REMEMBER.md)
found_by: development (P9-REMEMBER review, 2026-11-18)
links: fix=yes lesson=yes evidence=no toolgap=none

## Mechanism

The login Keychain is file-based: an item's access list trusts the build that made it. nhetrinh is ad-hoc
signed, so every build is a new app to it. A new build reading the old item needs the user (a dialog), and
can never delete or replace it. `LAContext.interactionNotAllowed` covers LocalAuthentication, not this list.

## How it shows

After an update: with interaction on, a Keychain dialog at launch, on the main thread before the tabs open
(not run: no dialog may reach the headmate's screen); with it off, `restored 0` at every launch and a quit
that cannot write, while the old build's cookies stay in the Keychain. With one account for every build
(round 2): an item first kept ad hoc is overwritten by every signed quit and read by no signed launch (-25293; RECHECK_P9_REMEMBER.md round 2).

## Fix

The fix entry, same path under `failfix/`.
