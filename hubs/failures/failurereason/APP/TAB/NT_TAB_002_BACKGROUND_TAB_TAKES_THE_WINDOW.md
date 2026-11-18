# NT-TAB-002 — Background tab takes the window

id: NT-TAB-002
family: TAB
status: OBSERVED
date: 2026-11-16
signature: ask selects the asking tab
source: _app/_Sources/_Nhetrinh/_Browser/Page/_Sheets.swift (`ask`: `select(index)` before the sheet)
links: fix=no lesson=no evidence=no toolgap=none

## Mechanism

Every page question (alert, confirm, prompt, sign-in, camera, a link to another app) first selects the
tab that asked. A background page that asks in a loop pulls the user to it each time; since P3-FIX-1 it
also ends the sheet of the tab that was shown (NT-UIX-004). Safari and Chrome keep a background tab's
dialog until that tab is selected.

## Confirm

From the code (P3-REVIEW P2). Not run. Fix waits for a ruling: hold the question until the tab is shown?
