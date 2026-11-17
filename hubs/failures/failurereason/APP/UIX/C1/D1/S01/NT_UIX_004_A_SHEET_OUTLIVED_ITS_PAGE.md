# NT-UIX-004 — A sheet outlived its page

id: NT-UIX-004
family: UIX
status: OBSERVED
date: 2026-11-16
signature: the sheet is still shown, the answer none
source: _app/_Sources/_Nhetrinh/_Browser/Page/_Sheets.swift on p3/pages 1d391d9 (`ask`)
source: _app/_Sources/_Nhetrinh/_Browser/Handling/_TabHandling.swift (`validateMenuItem`: Close Tab, Select Next Tab on)
links: fix=yes lesson=no evidence=no toolgap=none

## Mechanism

A sheet is window-modal: it blocks the sidebar and the page, not the menu bar, whose items target the
window controller. ⌘W and ⌃⇥ change the tab; nothing tied the sheet to the page that asked, so it stayed
on the window and the page waited for an answer.

## Confirm

`_SheetGapsTests` on 1d391d9: `after File > Close Tab: the selected tab is t3, the sheet is still shown,
the answer none`; the same after Tabs > Select Next Tab.
