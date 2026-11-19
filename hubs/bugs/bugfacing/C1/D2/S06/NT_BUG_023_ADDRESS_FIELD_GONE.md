# NT-BUG-023 — The address field disappears after a while

id: NT-BUG-023
family: UIX
status: FIXED
date: 2026-11-19
signature: address field gone, ⌘L does nothing
source: _app/Tests/NhetrinhTests/Tabs/Chrome/AddressFieldLayoutTests.swift
observed: reported by the headmate on the installed app (70bfe95), 2026-11-19; screen capture not kept (it showed a secret)
found_by: headmate (2026-11-19, "the address bar lost? i cannot Cmd L")
cause: NT-UIX-006
links: fix=yes lesson=no evidence=no toolgap=none

## Steps

Use nhetrinh for a while (pages, sidebar, window size changes), then look at the toolbar and press ⌘L.

Expected: the address field fills the toolbar right of the buttons; ⌘L selects its text.
Actual (70bfe95): the toolbar showed the buttons and an empty strip; there was no field to type or copy in.

## Fix

The toolbar row fills its width (`row.distribution = .fill`) and only the field stretches (hugging 1).
`AddressFieldLayoutTests` (red first: the field's layout was ambiguous at 480, 900 and 1600 points).
Not proven: the exact action that made the layout give the field no width (no capture of the live app);
the reinstalled app until the headmate uses it.
