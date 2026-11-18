# NT-BUG-008 — The settings file is read wrongly — fix

id: NT-BUG-008
family: UIX
status: OBSERVED
date: 2026-11-17
source: _app/Tests/_NhetrinhCoreTests/Prefs/PrefsReviewTests.swift (P4P6-FIX-1)
links: fix=yes lesson=no evidence=no toolgap=none

## Change

`Prefs.number` refuses a JSON boolean (an NSNumber of the CFBoolean type); minutes must be a whole number; a `zoom` that is not an object is ignored alone; hosts are lower-cased, read in sorted order.

## Proof

`PrefsReviewTests` (booleans, a bad zoom alone, lower case) and `unknownValuesFallBack` (`{"zoom": 3}` moved there from the corrupt-file list) red first, green with the fix. Not read back.
