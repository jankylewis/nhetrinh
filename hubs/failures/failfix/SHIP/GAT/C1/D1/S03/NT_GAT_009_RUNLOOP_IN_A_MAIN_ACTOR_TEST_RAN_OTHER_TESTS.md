# NT-GAT-009 — RunLoop in a main-actor test ran other tests — fix

id: NT-GAT-009
family: GAT
status: OBSERVED
date: 2026-11-16
source: _app/Tests/NhetrinhTests/TabHandlingTests.swift (`press(_:in:)`)
links: fix=yes lesson=no evidence=no toolgap=none

## Fix that holds

A test never runs the main run loop. A menu item is pressed now, as a click does
(`NSMenu.performActionForItem(at:)`); the probe's own deferred `.menu` stays covered by the readback.

## Wrong fix

A longer `RunLoop.run` or `.serialized`: the nested tests still run inside the wait.

## Proof

test.sh green after the change, 3 runs in P2-BUILD-1 (26 + 53 + 58 tests). Not on master.
