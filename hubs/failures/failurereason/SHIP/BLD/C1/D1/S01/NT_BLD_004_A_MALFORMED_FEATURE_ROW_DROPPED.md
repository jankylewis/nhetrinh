# NT-BLD-004 — A malformed feature row was dropped without a word

id: NT-BLD-004
family: BLD
status: OBSERVED
date: 2026-11-17
found_by: development (REVIEW_P8 R3)
signature: test_a_feature_row_of_the_wrong_shape_is_an_error
source: REVIEW_P8.md R3 (reviewer seat); the test is in 2fde920
links: fix=yes lesson=no evidence=no toolgap=none

## Mechanism

`parse_rows` kept only the lines its row pattern matched. A feature row with a missing column did
not match and was skipped, so the Release went out without that feature and no step failed.

## Confirm

`release_notes.parse_rows("| NT-FEAT-099 | A | abc1234 | - |")` on 2fde920 returns `[]`.

## Fix

The fix entry, same path under `failfix/`.
