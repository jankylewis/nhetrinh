# NT-BUG-008 — The settings file is read wrongly

id: NT-BUG-008
family: UIX
status: OBSERVED
date: 2026-11-17
signature: aBooleanIsNotMinutes
source: _app/_Sources/NhetrinhCore/Prefs/_Prefs.swift on p6/memory 96130c6 (`decode`)
source: _app/Tests/_NhetrinhCoreTests/Prefs/Store/PrefsReviewTests.swift
observed: found by the P4/P6 adversarial review (code read, then a test); no user report
links: fix=yes lesson=no evidence=no toolgap=none
cause: no failure reason filed: the mechanism is in the fix entry

## Steps

Edit `prefs.json`: `"idleUnloadMinutes": true`, or a zoom of `false`, or `"zoom": 3` next to a search engine, or a host written `Example.COM`.

Expected: a value of the wrong kind is ignored alone (ruling F7); hosts are read lower case.
Actual: from the code: `true` read as 1 minute, `false` as 50 %; a bad `zoom` made the whole file bad (engine, look, minutes reset, file moved to `prefs.bad.json`); `Example.COM` never applied (F4, F7, F10).
