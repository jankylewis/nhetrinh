# NT-UIX-004 — A sheet outlived its page — fix

id: NT-UIX-004
family: UIX
status: OBSERVED
date: 2026-11-16
source: _app/_Sources/_Nhetrinh/_Browser/Page/_Sheets.swift (`endSheets(of:)`, P3-FIX-1)
source: _app/_Sources/_Nhetrinh/_Browser/_Window/BrowserWindowController+Tabs.swift (`select`, `close(at:)`)
links: fix=yes lesson=no evidence=no toolgap=none

## Fix that holds

`ask` and the open panel keep each sheet with its page's web view (`Sheets.waiting`). `select` (leaving
a tab) and `close(at:)` end that page's sheets with `.abort` (the open panel: `cancel`): `ask` reports
-1, nothing pressed. So `alert` goes on, `confirm` is false, `prompt` nil, the sign-in and upload are
cancelled, and a camera question left unanswered is not remembered as refused. The menu stays on.

## Wrong fix

Turning ⌘W and ⌃⇥ off while a sheet is up: a page can then hold the window with a sheet loop.

## Proof

Red first on 1d391d9, green with the fix, red again under a mutation (P3-FIX-1, test.sh). Not read back.
Not proven: what WebKit does with a page's question when Back or Reload act on that page (not hooked).
