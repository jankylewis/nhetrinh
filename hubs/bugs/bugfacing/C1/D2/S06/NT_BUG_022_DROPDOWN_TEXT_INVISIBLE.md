# NT-BUG-022 — The address-bar dropdown cannot be read (dark Mac, light app)

id: NT-BUG-022
family: UIX
status: FIXED
date: 2026-11-19
signature: dark dropdown, black text
source: _app/Tests/NhetrinhTests/Tabs/Chrome/SuggestionLookTests.swift
observed: reported by the headmate on the installed P11 build (d826c82), 2026-11-19; no screen capture kept
found_by: headmate (2026-11-19, "i cannot see any content in the address bar dropdown")
links: fix=yes lesson=no evidence=no toolgap=none

## Steps

Set macOS to Dark, set nhetrinh's Appearance to Light, type a letter in the address bar.

Expected: the dropdown reads like the rest of the window (light background, dark text).
Actual (d826c82): a dark background under black text; also "Switch to tab" sat after a short title, not at the end.

## Cause

`SuggestionList.paint` read `NSColor.windowBackgroundColor.cgColor` outside drawing: the dynamic colour resolved in
the process's appearance (the Mac's Dark), while the labels resolved in the view's own (nhetrinh's Light).
The row's lines stack hugged its text, so "Switch to tab" followed the title.

## Fix

Both colours resolve inside `effectiveAppearance.performAsCurrentDrawingAppearance`, and a row repaints when its
appearance changes. The lines take the free width. Tests (red first, 3 issues): `SuggestionLookTests`, both
appearance pairs and the label's end. Not proven: the live look until the headmate sees the reinstalled app.
