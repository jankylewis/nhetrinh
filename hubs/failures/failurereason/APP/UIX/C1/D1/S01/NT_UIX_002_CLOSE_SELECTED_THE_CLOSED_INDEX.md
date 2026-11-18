# NT-UIX-002 — Close selected the closed index

id: NT-UIX-002
family: UIX
status: OBSERVED
date: 2026-11-16
found_by: development (P2-BUILD-1, code read then a mutation)
signature: the selected tab stays
source: _app/_Sources/_Nhetrinh/_Browser/_Window/BrowserWindowController+Tabs.swift on master 7176264 (`close(at:)`)
source: _app/_Sources/_Nhetrinh/UI/_SidebarView.swift on master 7176264 (`closeClicked`: the row's menu closes `clickedRow`)
links: fix=yes lesson=no evidence=no toolgap=none

## Mechanism

`close(at:)` was written for ⌘W, which closes the selected tab: after the removal it always set
`selected = -1` and selected the tab now at the closed index. The row's menu (P0) already closed
`clickedRow`, any row: closing a row that was not selected moved the selection to its neighbour.

## Confirm

`TabHandlingTests.rowMenuClosesThatRowAndReopenBringsItBack` with the old path (mutation, P2-BUILD-1):
`the selected tab stays` fails for row 1 and row 2 with row 3 selected.
