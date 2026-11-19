# NT-BUG-020 — A sign-in is lost after quit and relaunch — fix

id: NT-BUG-020
family: TAB
status: OBSERVED
date: 2026-11-18
source: _app/_Sources/NhetrinhCore/Prefs/SignIns/SignInKeeper.swift (P9-REMEMBER, nhetrinh_1; review fixes nhetrinh_2)
source: _app/_Sources/_Nhetrinh/Support/Secrets.swift (`KeychainSecrets`, `WebCookieJar`)
source: _app/_Sources/_Nhetrinh/AppDelegate.swift (`begin`, `quitTarget`)
links: fix=yes lesson=no evidence=no toolgap=none

## Change

Remember sign-ins after quit (D28, NT-FEAT-052): a clean quit keeps the session cookies in the Keychain, the
next launch sets them back before the first tab and deletes them. Review fixes (REVIEW_P9_REMEMBER.md):
Keychain calls run with user interaction off; round 2 (RECHECK_P9_REMEMBER.md): one item per profile again and
the build signed with the local identity, so sign-ins survive a reinstall (NT-BLD-006); the cookie-store seam
refuses outside the app; a quit while the cookies are still being set is clean and keeps the item; R51 claims
no count it does not read. P9-REMEMBER-2: ad-hoc and signed builds on their own accounts; a run refused
the item at launch writes nothing at quit (NT-BLD-006).

## Proof

Unit tests on in-memory seams (`SignInKeeperTests`, `CleanQuitTests`, `CookieCodingTests`, `SignInSeamTests`,
`SignInWiringTests`); the review's 8 new tests red on stubs, then green (test.sh). Mutations on the
session-only filter and the crash marker killed. Not on master. Not read back: R51, the real Keychain and
WebKit's cookie store.
