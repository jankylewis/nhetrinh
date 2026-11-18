# NT-GAT-011 — A step with no control passed a no-op

id: NT-GAT-011
family: GAT
status: FIXED
date: 2026-11-17
found_by: development (P4/P6 review, every step PASS at 00:18)
signature: R37 PASS with no tab left for the critical level to unload
source: _app/_Sources/NhetrinhReadback/_Steps/System/PressureSteps.swift on p6/memory 96130c6 (`playingTabSurvives`)
source: _app/_Sources/NhetrinhReadback/_Steps/Tabs/Tools/HubSteps.swift on p6/memory 96130c6 (`clearData`, `engine`)
observed: found by the P4/P6 adversarial review (code read); every step was PASS at 00:18
links: fix=yes lesson=no evidence=no toolgap=none

## Mechanism

A step checks only the side that holds when the action does nothing:
- R37 sent the critical level when row 2 was already unloaded and row 3 selected: no tab was left
  that critical must unload, so "row 1 still loaded" held for a critical level that did nothing.
- R30 sets its cookie seconds before Clear All: Clear Last Hour removes it too, so swapped buttons pass.
- R29 checked the engine once, never after a relaunch.

## Confirm

For each check, ask: would it fail if the action did nothing, or did the other choice?
