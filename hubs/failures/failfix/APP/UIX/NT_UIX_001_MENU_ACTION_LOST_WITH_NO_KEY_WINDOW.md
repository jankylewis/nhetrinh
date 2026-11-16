# NT-UIX-001 — Menu action lost with no key window — fix

id: NT-UIX-001
family: UIX
status: OBSERVED
date: 2026-11-16
source: _app/_Sources/_Nhetrinh/UI/AppMenu.swift (`build(browser:)`, browser items get `target`)
source: _app/_Sources/_Nhetrinh/AppDelegate.swift (menu built after the window controller)
source: _app/Tests/NhetrinhTests/_AppMenuTests.swift
links: fix=yes lesson=no evidence=yes toolgap=none

## Fix that holds

Every browser item (File, View, Tabs) targets the `BrowserWindowController` directly, so its
action needs no key window. The shortcuts are unchanged. Edit items (Undo to Select All) keep a
nil target: they act on the focused text through the responder chain. `AppDelegate` builds the
menu after the window controller exists. The item's target is weak; the delegate keeps the
controller.

## Wrong fix

Activating the app in the readback: it takes the user's focus (D18) and hides the defect
from the readback while a user with another app in front (Dock menu, Accessibility, Voice
Control) still meets it.

## Proof

Red first: 9 of 9 browser items resolved to `nil` with no key window. Then green, plus two
tests: each browser item keeps its ⌘ shortcut, each Edit item keeps a nil target.

Not proven: a readback run with the fix (this seat may not start the app; another seat holds it).
When one browser window has company (a future settings window), ⌘W still closes a tab: not
decided, revisit with D19.
