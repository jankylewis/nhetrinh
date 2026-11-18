# NT-BLD-004 — A malformed feature row was dropped without a word — fix

id: NT-BLD-004
family: BLD
status: OBSERVED
date: 2026-11-17
source: _app/scripts/install/release_notes.py (`parse_rows`)
links: fix=yes lesson=no evidence=no toolgap=none

## Fix that holds

Every line that starts `| NT-FEAT-` must match the shape its shelf's header declares (6 cells with
a Release note column, else 5), and a note may not be empty: else `ValueError` with the line number.
build.yml and release.yml run the tests and the script, so the build and the Release stop.

## Proof

P8-FIX-1: `test_a_feature_row_of_the_wrong_shape_is_an_error` red on 2fde920, green.
