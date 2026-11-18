# NT-BLD-005 — No ATS key in the bundle — lesson

id: NT-BLD-005
family: BLD
status: OBSERVED
date: 2026-11-18
links: fix=yes lesson=yes evidence=no toolgap=none

## Believed

Every readback page loaded, so loading pages worked: R9-R26 and R23's error page all ran over plain http.

## What changed it

The headmate met the error page on every plain http site; the matemaster's probe app showed ATS lets
localhost and IP addresses through with no key, and the readback serves only 127.0.0.1. Unqualified and
`.local` names are exempt too per Apple's docs as recalled (not proven).

## Rule

A test page on localhost, an IP address, an unqualified or a `.local` name proves nothing about the network
policy: test it on a qualified name (R52 uses a `.localhost` name and refuses an exempt one). A key the app needs is checked by the build, not remembered.
