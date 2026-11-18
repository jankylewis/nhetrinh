# NT-BUG-015 — Folders are lost with the last tab — fix

id: NT-BUG-015
family: TAB
status: OBSERVED
date: 2026-11-17
source: P7-FIX-1 on p7/prep (`foldersWithoutATabAreKept`)
links: fix=yes lesson=no evidence=no toolgap=none

## Change

`TreeSessionStore.load` keeps the folders and adds one home tab at the root's end, selected, with the saved sidebar width (`TreeSession.withHomeTab`).

## Proof

`foldersWithoutATabAreKept` red on e0b91ff, green; `nothingToRestoreGivesAHomeTab` still green. Not read back.
