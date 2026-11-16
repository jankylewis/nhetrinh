# NT-TG-004 — Readback instance outlived its run

id: NT-TG-004
family: GAT
status: OPEN
date: 2026-11-16
source: P1 close-out R2 run, 2026-11-16 22:13 (`open -W -n ~/Applications/nhetrinh-readback.app --args --steps R2 --log <tmp>`)
source: _app/_Sources/NhetrinhReadback/Driver/AppSession.swift (`quit`, `Ending.end`, `QuitOutcome`)
source: _app/Tests/NhetrinhReadbackTests/Steps/QuitTests.swift (`finalQuitEndsOnlyItsOwnInstance`, 3 cases)
observed: after `open -W` returned (R2 PASS, `exit: 0`), one nhetrinh process still ran: pid 88799,
observed: started 22:13:40, environment `NHT_PROFILE=readback` (the readback's own launch); still there ~20 s later
links: fix=yes lesson=no evidence=no toolgap=NT-TG-004

## Gap

The readback ends every run with `session.quit()`. Up to P1 that asked the app to quit
(`NSRunningApplication.terminate`), waited 5 s, then `forceTerminate`, waited 3 s, and forgot the
pid whatever happened: the run said nothing about an instance it left behind. The seat holder then
ended pid 88799 by hand (SIGTERM); the 22:09 R2 run left nothing.

Not proven: why the instance did not end. One reading, not checked: when
`NSRunningApplication(processIdentifier:)` gives nil, both requests are sent to nobody.

## Workaround (until the fix below is on master)

After a readback, `pgrep -fl 'Applications/nhetrinh.app'`; an instance with `NHT_PROFILE=readback`
is the readback's own and may be ended by its pid. Never end one without that profile: it is the headmate's.

## Fix (P1-FIX-1, not read back yet)

`quit()` asks to quit and waits 5 s for the exit; past that it sends signal 9 to the pid the
readback launched (never by name), waits 3 s, and returns `QuitOutcome`. The final quit's line
(`end: ...`) goes to stderr and into the report, so a left instance is said, never silent.
Not proven: that this ends the 22:13 kind of instance (it was not seen again).
