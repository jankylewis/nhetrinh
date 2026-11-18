# NT-BUG-019 — Plain http pages fail with the error page — fix

id: NT-BUG-019
family: NAV
status: OBSERVED
date: 2026-11-18
source: _app/scripts/_build.sh (`NSAppTransportSecurity` in the Info.plist, and the check after it, P8-ATS-1)
source: _app/_Sources/NhetrinhCore/_Navigation/ErrorPage.swift (`title(for:)`, -1022)
source: _app/_Sources/NhetrinhReadback/_Steps/Tabs/Pages/Basics/LoadSteps.swift (R52)
links: fix=yes lesson=yes evidence=no toolgap=none

## Change

The Info.plist gets `NSAppTransportSecurity` with `NSAllowsArbitraryLoadsInWebContent` true: web content
only, nothing else relaxed. The build stops when that dict is anything else (missing, false, or another
key added). An ATS refusal now says "This site needs a secure connection" (NT-BLD-005).

## Proof

`errorPageSaysTheReason` and `errorPageTitleIsTheReason` (-1022) and the R52 tests (`PlainHTTPTests`) red on
stubs, green with the fix (P8-ATS-1, test.sh). `_build.sh` passes and `plutil -p` of the built Info.plist
shows the key; the check fails on plist copies with the key missing, false, or with
`NSAllowsArbitraryLoads` added. R52 written, not read back. Not on master.
Review fixes (reviewer seat, tests red first): the report header lists R52; R52 refuses an ATS-exempt name
before it acts (`theStepRefusesAnExemptName`, NOT READ BACK); `exemptFromATS` also counts unqualified and
`.local` names. The `.localhost` name resolves to `::1` first and the readback's server listens on 127.0.0.1
only: a URLSession fetch of `http://site.localhost:<port>/` from a 127.0.0.1-only server gave 200 in 30 ms
(CFNetwork falls back; reviewer seat, 2026-11-18, not kept). Not proven: the same in WebKit's network
process; a page loads on the installed app; the unqualified and `.local` exemptions (Apple docs, recalled).
