# NT-BUG-030 — a long address wraps onto a second line in the address bar

id: NT-BUG-030
family: CHROME
status: FIXED
date: 2026-11-27
signature: the address bar shows a long address on two lines, the second cut in half
source: the headmate's screenshot (2026-11-27), a document page whose address has a long query; not kept here
  (work page)
observed: on the installed 36db960, 2026-11-27
found_by: headmate (2026-11-27, "bug, note to do later")
links: fix=yes lesson=no evidence=no toolgap=none

## Steps

1. Open a page whose address is wider than the address bar (a long query string).
2. Look at the address bar, without clicking it.

Expected: one line, cut at the end (as Safari and Chrome do); the whole address scrolls while editing.
Observed: the text wraps onto a second line, and the bar's height cuts the second line in half.

## Cause

`ToolbarView.address` was a plain `NSTextField()`: its cell wraps by default. Proven by the red test: a 500-character
address measured two lines high in the field's width.

## Fix

- `ToolbarView.setUpAddress` (`ToolbarView+Typing.swift`): one line (`usesSingleLineMode`), no wrap, cut at the end
  (`.byTruncatingTail`). The field editor still scrolls the text while editing.
- Test: `aLongAddressStaysOnOneLine` (60 and 500 characters; red before the fix, red again with the three lines
  removed: mutation check).

Not read back on the installed app yet.
