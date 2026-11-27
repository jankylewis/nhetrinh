# NT-BUG-030 — a long address wraps onto a second line in the address bar

id: NT-BUG-030
family: CHROME
status: OPEN
date: 2026-11-27
signature: the address bar shows a long address on two lines, the second cut in half
source: the headmate's screenshot (2026-11-27), a document page whose address has a long query; not kept here
  (work page)
observed: on the installed 36db960, 2026-11-27
found_by: headmate (2026-11-27, "bug, note to do later")
links: fix=no lesson=no evidence=no toolgap=none

## Steps

1. Open a page whose address is wider than the address bar (a long query string).
2. Look at the address bar, without clicking it.

Expected: one line, cut at the end (as Safari and Chrome do); the whole address scrolls while editing.
Observed: the text wraps onto a second line, and the bar's height cuts the second line in half.

## Cause (not proven)

`ToolbarView.address` is a plain `NSTextField()`: its cell wraps by default. No `usesSingleLineMode`,
`lineBreakMode` (`.byTruncatingTail`) or `cell.isScrollable` is set. Not checked by a test or a run yet.

## To do

A test first: a field with a 500-character address keeps one line (`cell.wraps == false`, the text's height one
line). Then set the field to one line, cut at the end, scrolling while editing. Read back on the installed app.
