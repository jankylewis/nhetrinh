# NT-PRF-003 — Favicon decoded at full pixel size

id: NT-PRF-003
family: PRF
status: OBSERVED
date: 2026-11-16
signature: anIconOfHugePixelSizeIsRefusedBeforeItIsDecoded
source: _app/_Sources/_Nhetrinh/_Browser/Handling/Favicons.swift on p2/sidebar cc8affe (`small`, `largest`)
source: _app/Tests/NhetrinhTests/Tabs/ReviewGapsTests.swift `anIconOfHugePixelSizeIsRefusedBeforeItIsDecoded`
observed: a standalone copy of `small`'s drawing, `/usr/bin/time -l`, peak memory footprint: 32 px PNG of 178 bytes 4.9 MB; 5000 x 5000 PNG of 436 853 bytes 106 MB; 6000 x 6000 PNG of 629 009 bytes 151 MB (P2-REVIEW; the program and files were not kept)
links: fix=yes lesson=no evidence=no toolgap=none

## Mechanism

`Favicons` caps an icon file at 512 KB, which bounds its bytes, not its pixels. `small` draws the
`NSImage` into a 32 px bitmap, and drawing decodes the whole image first: 4 bytes a pixel. A PNG
of one colour compresses to a few hundred KB at 5000 px a side, so one page's
`<link rel="icon">` costs about 100 MB for a moment, against an app budget of 40 MB.

## Confirm

The test on cc8affe: a 4000 px, 1-bit PNG under the cap gives an icon (`small(png) != nil`).
Peak memory: the measurement above. Not measured inside the app: not proven how far the app's
footprint rises, only that the decode is sized by the pixels.
