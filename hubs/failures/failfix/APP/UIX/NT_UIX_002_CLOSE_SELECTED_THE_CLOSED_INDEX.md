# NT-UIX-002 — Close selected the closed index — fix

id: NT-UIX-002
family: UIX
status: OBSERVED
date: 2026-11-16
source: _app/_Sources/_Nhetrinh/_Browser/_Window/BrowserWindowController+Tabs.swift (`close(at:)`, P2-BUILD-1)
source: _app/_Sources/_Nhetrinh/UI/_Sidebar/TabTable.swift (`menuRow`: the row the menu was shown on)
links: fix=yes lesson=no evidence=no toolgap=none

## Fix that holds

Only a closed selected tab selects another. Any other row: removed, the selection index shifts
when the row was above it, the chrome is refreshed. The row's menu closes the row it was shown
on (`TabTable.menuRow`), kept by the table, not AppKit's `clickedRow`.

## Wrong fix

Re-selecting the selected tab after every close: it reloads nothing but re-runs `select`, which
moves the first responder and the idle clock of a tab the user did not touch.

## Proof

Red first: failed on the old `close(at:)` in the first P2 test run; green with the fix; red again
under a mutation that restores the old path (P2-BUILD-1).
Not proven: R13 on the installed app.
