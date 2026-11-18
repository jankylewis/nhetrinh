# NT-GAT-010 — Probe read sheet buttons in view order

id: NT-GAT-010
family: GAT
status: OBSERVED
date: 2026-11-16
found_by: readback (R20 FAIL, readback 2026-11-16 22:50)
signature: the confirm sheet's buttons are ["Cancel", "OK"]
source: readback run of P3-BUILD-1, 2026-11-16 22:50 (`--steps R19-R26`), build 93f693e+, R20 FAIL
source: _app/_Sources/_Nhetrinh/_Browser/Page/SheetProbe.swift (`readSheet`)
links: fix=yes lesson=no evidence=no toolgap=none

## Mechanism

The probe lists a sheet's buttons by walking its views. An `NSAlert` built with OK then Cancel
holds them in its view tree as Cancel, OK; R20 compared the list to `["OK", "Cancel"]` and failed
although the app was right.

## Confirm

R20 PASS at the next run (`confirm: a sheet [OK, Cancel]; Cancel: false, OK: true`) once R20 and
R26a compare the buttons as a set. Not proven: that the view order is the same on every macOS.

## Fix

The steps compare sheet buttons as a set; the probe's order is not the alert's order.
