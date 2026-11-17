# NT-BUG-003 — New Tab from the menu does nothing — fix

id: NT-BUG-003
family: UIX
status: FIXED
date: 2026-11-16
source: _app/_Sources/_Nhetrinh/UI/AppMenu.swift (`build(browser:)`)
source: _app/_Sources/_Nhetrinh/AppDelegate.swift
source: _app/Tests/NhetrinhTests/_AppMenuTests.swift `browserItemReachesTheBrowserWithNoKeyWindow`
links: fix=yes lesson=no evidence=yes toolgap=none

## Change

Browser menu items target the window controller instead of the responder chain
(`hubs/failures/failfix/APP/UIX/C1/D1/S01/NT_UIX_001_MENU_ACTION_LOST_WITH_NO_KEY_WINDOW.md`).

## Proof

Red first: with no key window, 9 of 9 browser items reached `nil`. Then green.
Not proven: R5 and R6 passing on the installed app (not read back yet).

## Proof on master (0f99aee)

`hubs/failures/evidence/readback/_LATEST.md` (2026-11-16 21:24, PASS 8 of 8; app 0.1.0 built from fba7d9e, whose app sources equal master 0f99aee), R5: `File > New Tab (⌘T): rows 1 to 2; File > Close Tab (⌘W): back to 1`; red-first test green in CI run 43885459211 (PR #1, head 402adec, the same tree as master 0f99aee).
