# NT-UIX-006 — The address field's width was ambiguous

id: NT-UIX-006
family: UIX
status: FIXED
date: 2026-11-19
found_by: headmate (cause of NT-BUG-023, 2026-11-19)
signature: theFieldFillsTheRowAndIsNotAmbiguous
source: _app/_Sources/_Nhetrinh/UI/Bars/_Toolbar/_ToolbarView.swift on 70bfe95 (`NSStackView(views:)`, default distribution)
source: _app/Tests/NhetrinhTests/Tabs/Chrome/AddressFieldLayoutTests.swift
links: fix=yes lesson=no evidence=no toolgap=none

## Mechanism

The toolbar row is an `NSStackView` with its default distribution (gravity areas). With the zoom badge hidden
(100 %, the usual case) the stack detaches it, and the field's right edge is only held by `field <= row end`.
The field has no width of its own and hugs at the same priority as the stack: nothing decides its width.
Auto Layout picks one; a later layout may pick a zero width. `hasAmbiguousLayout` was true at every width.

## Rule

A field that must fill a stack row: `distribution = .fill` and the lowest hugging priority on that field.
Test it with `hasAmbiguousLayout`, not only the width one layout happened to give.
