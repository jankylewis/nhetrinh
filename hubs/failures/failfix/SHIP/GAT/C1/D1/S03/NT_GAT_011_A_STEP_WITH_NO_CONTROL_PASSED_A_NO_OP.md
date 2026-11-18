# NT-GAT-011 — A step with no control passed a no-op — fix

id: NT-GAT-011
family: GAT
status: FIXED
date: 2026-11-17
source: _app/_Sources/NhetrinhReadback/_Steps/System/PressureSteps.swift (`freshBackgroundTab`, P4P6-FIX-1)
source: _app/_Sources/NhetrinhCore/Prefs/ClearRange.swift and `ClearRangeTests` (P4P6-FIX-1)
source: _app/_Sources/NhetrinhReadback/_Steps/Tabs/Tools/HubSteps.swift (`keptAfterRelaunch`, P4P6-FIX-1)
links: fix=yes lesson=no evidence=no toolgap=none

## Fix that holds

- R37: before the critical level a silent tab is opened and left (row 4, used seconds ago): a warning
  keeps it, only critical unloads it. The step needs `[true, false, true, false]`.
- R30 keeps the readback (Clear All removes the cookie); which button removes what is a pure function
  (`ClearRange`), unit-tested: the readback cannot make a cookie older than an hour.
- R29: after Quit and a launch, the same words go to DuckDuckGo again.

## Proof

`ClearRangeTests` red on a stub, green with the fix (test.sh). R29 and R37 changed, not read back yet
(the seat was with another mate during P4P6-FIX-1).
