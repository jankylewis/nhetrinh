# NT-NAV-003 — Camera answer kept per host — fix

id: NT-NAV-003
family: NAV
status: OBSERVED
date: 2026-11-16
source: _app/_Sources/NhetrinhCore/_Navigation/SitePermissions.swift (`site(scheme:host:port:)`, P3-FIX-1)
links: fix=yes lesson=no evidence=no toolgap=none

## Fix that holds

Answers are kept per site = scheme, host, port (a default port and the case do not matter), built in
Core from `WKSecurityOrigin`'s protocol, host and port. The question still names the host.

## Proof

`aSiteIsAnOrigin` green; red under a mutation keying by host (P3-FIX-1, test.sh). Not read back.
