# NT-BLD-003 — Release notes printed the hub record — fix

id: NT-BLD-003
family: BLD
status: OBSERVED
date: 2026-11-17
source: _app/scripts/install/release_notes.py (`parse_rows`, `noted`, `NOT_FOR_USERS`, `INTERNAL`); hubs/product/features/S01.md, S02.md
links: fix=yes lesson=no evidence=no toolgap=none

## Fix that holds

The feature shelves have a Release note column, written for a user of the release: what the app
does now, no class or API name, no id, no readback. A change that alters a shipped feature edits
the older rows' notes in the same change (or writes `-`: the row is left out). The script prints
that column only, and refuses a note with a hub id, a task id, a decision id (`D19`), a backticked
code name or the readback in it. A noted row is split on unescaped `|` and must have exactly six
cells: a `|` in a note is written `\|`; a bare one is an error, never a note cut short.

## Wrong fixes

1. Strip more words by pattern from the Feature text: a class name has no pattern, and an old row
   still describes old behaviour.
2. Read a noted row with one regex whose Feature cell is greedy: a bare `|` in the note moved its
   left part into Feature and published the rest, no error (P8-VERIFY (a)).

## Proof

P8-FIX-1: `ReviewP8Tests` red on 2fde920, green; the new tests (a Release note column, `-`, an
internal word refused) pass. P8-FIX-2, tests red on a81415b: a decision id note `ValueError not
raised`; an escaped `\|` note refused as the wrong shape (the bare `|` cut: P8-VERIFY (a)); green
after. Not on `master`; no Release made yet.
