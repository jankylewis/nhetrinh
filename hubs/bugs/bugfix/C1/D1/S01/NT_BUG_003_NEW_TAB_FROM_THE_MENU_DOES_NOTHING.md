# NT-BUG-003 — New Tab from the menu does nothing — fix

id: NT-BUG-003
family: UIX
status: OBSERVED
date: 2026-11-16
source: _app/_Sources/_Nhetrinh/UI/AppMenu.swift (`build(browser:)`)
source: _app/_Sources/_Nhetrinh/AppDelegate.swift
source: _app/Tests/NhetrinhTests/_AppMenuTests.swift `browserItemReachesTheBrowserWithNoKeyWindow`
links: fix=yes lesson=no evidence=yes toolgap=none

## Change

Browser menu items target the window controller instead of the responder chain
(`hubs/failures/failfix/APP/UIX/NT_UIX_001_MENU_ACTION_LOST_WITH_NO_KEY_WINDOW.md`).

## Proof

Red first: with no key window, 9 of 9 browser items reached `nil`. Then green.
Not proven: R5 and R6 passing on the installed app (not read back yet).
