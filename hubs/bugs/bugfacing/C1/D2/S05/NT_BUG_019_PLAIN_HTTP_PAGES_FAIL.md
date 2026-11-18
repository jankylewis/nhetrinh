# NT-BUG-019 — Plain http pages fail with the error page

id: NT-BUG-019
family: NAV
status: OBSERVED
date: 2026-11-18
found_by: headmate (reported 2026-11-18: a dev-server page on a .localhost name failed in nhetrinh, loaded in another browser)
signature: NSURLErrorDomain -1022
source: _app/scripts/_build.sh on 849c3e3 (the Info.plist it writes has no NSAppTransportSecurity key)
source: _app/_Sources/NhetrinhCore/_Navigation/ErrorPage.swift on 849c3e3 (`title(for:)`: -1022 falls to the default)
observed: seen by the headmate on the installed app (P8-ATS-1 brief); no screen capture kept
observed: matemaster probe app, bundled with no ATS key: http on a .localhost name and on a public site give
  NSURLErrorDomain -1022; http on localhost and 127.0.0.1 give 200 (P8-ATS-1 brief; the probe is not kept)
links: fix=yes lesson=yes evidence=no toolgap=none
cause: NT-BLD-005

## Steps

Type a plain http address whose host is a name, for example `http://site.localhost:8080/`, Return.

Expected: the page loads, as https pages and http pages on localhost do.
Actual (849c3e3, headmate): the error page "This page could not be loaded", for every plain http page except
localhost and IP addresses (unqualified and `.local` names: exempt per Apple's docs as recalled, not proven).

## Cause

App Transport Security refuses the load before it is sent: the bundle has no ATS key (NT-BLD-005). The error
page said nothing of it: `ErrorPage.title(for:)` had no words for -1022.
