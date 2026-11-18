# NT-BLD-003 — Release notes printed the hub record

id: NT-BLD-003
family: BLD
status: OBSERVED
date: 2026-11-17
found_by: development (REVIEW_P8 R1, R2)
signature: test_the_real_notes_do_not_contradict_themselves
source: REVIEW_P8.md R1, R2 (reviewer seat, outside the repository: its tests are in 2fde920)
source: _app/scripts/install/test_release_notes.py (`ReviewP8Tests`, red on 41fc9df + p7/prep)
links: fix=yes lesson=no evidence=no toolgap=none

## Mechanism

`release_notes.py` printed every feature row's Feature text. That column is the hubs' record: rows
are only added, a later fix never edits the row it changes, and the text names classes, APIs, task
ids and the readback. So the notes said "up to 3 download rows" next to "every running download has
a row", ⌃⇥ and Move Tab Up as before P7-FIX-1, and `DownloadNamer`, `WKDownload`, "the readback".
Removing words by pattern cannot find a class name.

## Confirm

`python3 _app/scripts/install/release_notes.py 1.0.0` on 2fde920: the stale and internal lines print.

## Fix

The fix entry, same path under `failfix/`.
