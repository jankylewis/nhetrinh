# NT-NAV-008 — A line separator kept in a file name

id: NT-NAV-008
family: NAV
status: OBSERVED
date: 2026-11-17
signature: cleanRemovesLineBreakingSeparators
source: _app/_Sources/NhetrinhCore/_Navigation/Downloads/_DownloadNamer.swift on e7dccf9 (`clean`)
source: nhetrinh_wt/REVIEW_P5.md (P5-REVIEW, outside the repository)
links: fix=yes lesson=no evidence=no toolgap=none

## Mechanism

`clean` removed control characters (Cc, Cf) only. U+2028 and U+2029 are separators (Zl, Zp): they stayed and break the name over two lines, as `\n` would.

## Confirm

`cleanRemovesLineBreakingSeparators` red on e7dccf9.
