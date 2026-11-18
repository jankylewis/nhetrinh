# NT-BLD-005 — No ATS key in the bundle

id: NT-BLD-005
family: BLD
status: OBSERVED
date: 2026-11-18
found_by: headmate (cause of NT-BUG-019, reported 2026-11-18; mechanism proven by a bundled WKWebView probe without and with the key)
signature: NSURLErrorDomain -1022
source: _app/scripts/_build.sh on 849c3e3 (the Info.plist heredoc: no NSAppTransportSecurity)
observed: matemaster probe app, bundled with no ATS key: http on a .localhost name and on a public site give
  -1022; on localhost and 127.0.0.1 give 200 (P8-ATS-1 brief; the probe is not kept)
links: fix=yes lesson=yes evidence=no toolgap=none

## Mechanism

A bundled app is under App Transport Security: with no `NSAppTransportSecurity` key it refuses plain http,
before the request is sent, to every host but localhost and IP addresses. Per Apple's ATS documentation as
recalled, unqualified names and `.local` names are exempt too: not proven (no probe on them). WKWebView loads
count. WebKit
reports `NSURLErrorAppTransportSecurityRequiresSecureConnection` (-1022), and the error page had no words
for it, so it read "This page could not be loaded".

## How it shows

Every plain http page on a name fails; https and http on localhost or 127.0.0.1 load. A readback on the
readback's own server (127.0.0.1) cannot see it.

## Confirm

`plutil -p <app>/Contents/Info.plist | grep NSAppTransportSecurity` prints nothing on a build of 849c3e3.

## Fix

The fix entry, same path under `failfix/`.
