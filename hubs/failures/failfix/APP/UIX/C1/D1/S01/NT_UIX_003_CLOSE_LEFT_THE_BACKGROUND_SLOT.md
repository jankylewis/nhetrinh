# NT-UIX-003 — Close left the background slot — fix

id: NT-UIX-003
family: UIX
status: OBSERVED
date: 2026-11-16
source: _app/_Sources/_Nhetrinh/_Browser/_Window/BrowserWindowController+Tabs.swift (`close(at:)`, P2-FIX-1)
links: fix=yes lesson=no evidence=no toolgap=none

## Fix that holds

In `close(at:)`, after the removal: when the closed index is below the slot, the slot moves up by
one. A closed selected tab still resets it through `select`.

## Wrong fix

Resetting the slot on every close: the next background tab would go right after the selected tab,
before the tabs opened from it earlier, and reverse their order.

## Proof

Red first on cc8affe, green with the fix, red again under a mutation that removes the shift
(P2-FIX-1, test.sh). Not read back. Not on master.
