# NT-BLD-005 — No ATS key in the bundle — fix

id: NT-BLD-005
family: BLD
status: OBSERVED
date: 2026-11-18
source: _app/scripts/_build.sh (`NSAppTransportSecurity`, and the check after the Info.plist is written)
links: fix=yes lesson=yes evidence=no toolgap=none

## Fix that holds

`NSAllowsArbitraryLoadsInWebContent` true: the web view may load plain http, the app's own loads stay under
ATS. The build reads the dict back with `plutil -extract` and stops unless it is exactly that one key, so
the key cannot be dropped and the exception cannot be widened without the build failing.

## Wrong fix

`NSAllowsArbitraryLoads` true: it relaxes every load of the app, not only web content (P8-ATS-1 brief).

## Proof

P8-ATS-1: the built Info.plist shows the key (`plutil -p`); the check fails on copies with the key missing,
false, or `NSAllowsArbitraryLoads` added. R52 written, not read back.
